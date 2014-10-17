function [time_series, fir, fs] = match_spectra(X, Y, varargin)
%% DESCRIPTION:
%
%   This function can be used to match the spectra of two time series.
%   Below is an approximate outline of the procedure implemented here.
%   Please note that there are *many* ways to do spectral matching and this
%   may not be the best solution for your specific circumstance. This
%   function uses a spectral estimator (pwelch) to estimate the PSDs of two
%   time series and then attempts to filter these time series such that the
%   PSDs are a close approximation of each other. 
%
%   Note that SIN_matchspectra provides an alternative method, but tends to
%   be very slow and generally overfits the data. CWB wrote this as a
%   faster, more streamlined, and more principled alternative. 
%
%   Procedure:
%
%       1. Estimate the power spectral densities (PSDs) of the reference
%       and to-be-matched time series.
%
%       2. Compute the difference between the spectral densities in
%       decibels. This is the approximate frequency response we hope to
%       model.
%
%       3. Divide the difference computed in step 2 by 2. The division is
%       required because we will use filtfilt below, which essentially
%       doubles the filter order and the frequency response (in decibels).
%
%       4. Create an finite impulse response of order filter_order (see
%       parameters below) to approximate the frequency response.
%
%       5. Apply the filter to the to-be-matched time series.
%
%   The spectra of the resulting time series should closely match the
%   reference time series.
%
% INPUT:
%
%   X:          Reference time series or file path to the reference time
%               series. If the latter, then fsx must be defined
%               below. Must be a single channel time series (column vector). 
%
%   Y:          to-be-matched time series. Must be a single channel
%               (column)
%
% Time series parameters:
% 
%   'fsx':  sampling rate of reference time series
%
%   'fsy':  sampling rate of to-be-matched time series
%
% Filtering parameters:
%
%   Parameters below provide specifications for filter created in call to
%   fir2 to do spectral matching. 
%
%   'frequency_range':  two-element double vector, specifying the frequency
%                       bounds of the frequency response that should be
%                       used for filter creation. The gain applied to all
%                       values outside this frequency range is 0 dB
%                       (magnitude of 1)
%
%   'filter_order': FIR filter order used in call to fir2. (e.g., 100)
%
% Spectral Estimation:
%
%   Parameters used in call to pwelch for spectral estimation. 
%
%   'window':   window length (in seconds) (e.g., 1)
%
%   'noverlap': number of overlapping samples in time windows.
%
%   'nfft': number of points used in FFT computation. 
%
% Visualization:
%
%   
% OUTPUT:
%
%   time_series:    the filtered (spectrally matched) time series (Y).
%
%   fir:    impulse response of FIR. *Remember* that this will be the FIR
%           used in a call to filtfilt!
%
%   fs: sampling rate
%
% Development:
%
%   None (yet)  
%       
% Christopher W Bishop
%   University of Washington
%   10/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% LOAD DATA
%   Loads the data or reads from file, depending on what the user provides.
[X, fsx] = SIN_loaddata(X, 'maxts', 1); 
[Y, fsy] = SIN_loaddata(Y, 'maxts', 1); 

% Catch in case sampling rate unknown after file load
if isempty(fsx)
    fsx = d.fsx;
end % if isempty(fsx)

if isempty(fsy)
    fsy = d.fsy;
end % if isempty(fsy)

% Define the sampling rate we'll be working with
fs = max([fsx fsy]); 

% Resample data
%   If sampling rates do not match, this will upsample the lower sampling
%   rate to match the higher of the two.
X = resample(X, fs, fsx);
Y = resample(Y, fs, fsy); 

%% COMPUTE PSDs
%   Compute one-sided PSDs
[Pxx, freqs] = pwelch(X, d.window, d.noverlap, d.nfft, fs);
Pyy = pwelch(Y, d.window, d.noverlap, d.nfft, fs);

%% COMPUTE PSD DIFFERENCE
%   PSD difference is computed in DECIBELs. Makes some of the math below
%   easier on CWB's mind.
PSD_diff = db(Pxx, 'power') - db(Pyy, 'power'); 

%% RESTRICT FREQUENCY RANGE
%   We only want to correct for differences within the specified frequency
%   range.
frequency_mask = SIN_maskdomain(freqs, d.frequency_range); 

% Set all differences outside of the frequency range to 0 dB.
PSD_diff(~frequency_mask) = 0; 

%% DESIGN FILTER (FIR2)
%   Also divide the filter_order by 2 since using filtfilt doubles the
%   filter order. 
%
%   Divide PSD differences by 2 since we want to create an FIR compatible
%   with filtfilt.
fir = fir2(d.filter_order/2, freqs./(fs/2), db2amp(PSD_diff./2));

%% FILTER TIME SERIES
time_series = filtfilt(fir, 1, Y); 

%% CALCULATE PSD OF FILTERED WAVEFORM
Pts = pwelch(time_series, d.window, d.noverlap, d.nfft, fs);

%% VISUALIZATION
if d.plot
    
    % PSD of time series
    figure, hold on
    plot(freqs, db([Pxx, Pyy, Pts], 'power'));
    title('PSDs');
    legend('Reference', 'Original', 'Matched', 'FIR');
    xlabel('Frequency (Hz)')
    ylabel('PSD (dB/Hz)');
    set(gca, 'XScale', 'log')
    grid on    
       
end % if d.plot