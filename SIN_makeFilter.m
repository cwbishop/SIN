function [filt]=SIN_makeFilter(varargin)
%% DESCRIPTION:
%
%   This function creates a finite impulse response (FIR) using MATLAB's
%   FIR2 (or FIRLS, maybe) functions. The function can accept arbitrary
%   length time serires (tsdata) or frequency series (fsdata). However, at
%   the time of writing, all of the input data must be in the same format. 
%
% INPUT:
%
%   X1, X2 ... Xn:  time or frequency series are the first N arguments.
%                   Each series is named X1, X2, etc. in ascending order.
%                   This allows the user to pass arbitrary mathematical
%                   operations that will be performed on the PSD functions
%                   (in dB) of these time series.
%
% General Parameters:
%
%   'fs':   double, sampling rate in Hz. Note that the function assumes
%           that all data series have the same sampling rate. If this is
%           NOT the case, resample the data ahead of time.
%
%           Similarly, the code assumes that there are the same number of
%           points in frequency series. If this is not the case,
%           interpolate so they match ahead of time. 
%
%   'plev': integer, if non-zero, summary plots are generated.
%       0:  no plots generated
%       1:  XXX Need to figure out what to plot XXX   
%
%   'datatype': string, type of data. Note that all entered time series
%               must be of the same data type (at least at the time this
%               was written).
%                   'tsdata':   time series
%                   'fsdata':   frequency series   
%
%   'domath':   string describing the mathematical operation to perform
%               between the PSDs (in dB) of each time series. 
%
%               Example: 'X1 - X2' finds the difference between X1 and X2
%               (in dB). 
%
%               This approach proved useful when combining PSD estimates
%               from multiple data series in a flexible way. (see
%               SIN_calibrate for example).
%
%               If no "fancy math" is necessary, simply set field to 'X1'
%               or whichever data series you want to fit with a filter. 
%
%               Note: to estimate a filter appropriate for use with
%               'filtfilt', you must divide the frequency response by 2.
%               (E.g., (X1-X2)/2). 
%
% Power Spectral Density Estimation:
%
%   'window':  the window used for spectral estimation. If this is an
%               integer value, then we assume this is the time (in sec)
%               of a window. For instance, if window = 1, then we
%               compute spectra in 1 sec windows. 
%
%   'noverlap': number of samples of overlap between sequential
%                   spectral estimates. (default=[]; so whatever the
%                   spectral estimator uses).
%   
%   'nfft':     integer, number of frequency bins in FFT. Must be at
%               least as large as the number of samples in the longest
%               signal in the series (X or Y). 
%
% Filter Creation Parameters:
%
%   'frange':   two element array, min and max of frequency range to
%               correct (e.g., [-Inf Inf] to correct full frequency range)
%
%               XXX Not used currently XXX
%
%   'filter_order':   integer, FIR filter order. 
%
%   Frequency domain smoothing:
%
%   'smoothPSD':    bool, if set, the PSD function AFTER the mathematical
%                   operation is applied (see above) is smoothed in the
%                   frequency domain prior to filter estimation.
%
%   'KernelSize':   double, kernel size (in Hz). This is matched as closely
%                   as possible, but don't bank on it being precise if you
%                   feed it some stupid fraction.
%
% Development:
%
%   1. What to do about DC component? Should this be removed? 
%
%   2. How do we match levels? RMS of filtered stimuli will differ from the
%   input stimulus. How do we match levels? Or should we offer a way to
%   remove the mean power to prevent level changes??
%
%   3. Add support for frequency series with varying number of data points.
%   This will require interpolation of the frequency series (maybe linear
%   interpolation in dB space? Using interp1?)
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% GATHER TIME SERIES
%   The first N inputs are time (or frequency) series that must be loaded
%   into p. 
for n=1:nargin
    
    % Break as soon as we encounter the first key/value pair
    if ischar(varargin{n})
        break
    end % if ischar ...
    
end % for n=1:nargin

%% GATHER KEY/VALUE INPUTS
%   Place all key/value pairs into data structure
p=varargin2struct(varargin{n:end});

%% GATHER DATA SERIES
%   Data are loaded using SIN_loaddata.
for i=1:n-1
        
    % Set FS if we need to
    if isfield(p, 'fs'), t.fs=p.fs; end 
    
    % Set accepted data types
    t.dtype=[1 2]; % accept wav and single/double data traces
    t.maxts=1; % only one data trace per variable. 
    
    % Load data  
    dsname = ['X' num2str(i)]; % data series name
    [p.(dsname), fs]=SIN_loaddata(varargin{i}, t); 
    
    % Set FS for analyses below
    if ~exist('FS', 'var'), FS=fs; end
    
    % Sampling rate error check
    %   This will only work for WAV files. If the returned sampling rates
    %   differ, then we throw an error.
    if FS~=fs, error('Mismatched sampling rates. Resample and try again.'); end 
    
    % Convert to PSD
    %   Convert to PSD if the data are a time series
    if isequal(p.datatype, 'tsdata')
        
        % Compute average PSD
        [p.(dsname), f] = pwelch(p.(dsname), p.window, p.noverlap, p.nfft, FS);
        
    end % if isequal(... 
    
    % Convert to dB
    %   Use 'power' since pwelch returns a power estimate
    p.(dsname) = db(p.(dsname), 'power'); 
       
    % Copy field over into variable
    %   Makes evaluating the mathematical operation easier below
    eval([dsname '=p.(''' dsname ''');']); 
end % for i=1:n

%% PERFORM MATHEMATICAL OPERATION
fresp = eval(p.domath); % frequency response

%% SMOOTH 
%   Smoothing can be applied
if p.smoothPSD
    
    % Convert KernelSize from Hz to number of points
    p.KernelSize = ceil(p.KernelSize/f(2)); % divide Kernel size by the frequency step size
    fresp = smooth1q(fresp, p.KernelSize); 
    
end % if p.smoothPSD

%% ESTIMATE FINITE IMPULSE RESPONSE (FIR)
%   Estimates the FIR filter for use by 'filter' or 'filtfilt'; which
%   filtering method should be used depends on the mathematical operation
%   applied.
%
%   Convert frequencies returned from pwelch to normalized frequency range
%   [0 Nyquist]. 
%
%   Convert decibel scale back to magnitude (amplitude) for filter fitting.
filt = fir2(p.filter_order, f./(FS/2), db2amp(fresp)); 

%% DIAGNOSTICS
%   Run some diagnostics and generate some plots.
%       - Plot frequency response of each data series 
%       - Plot 'ideal' frequency response (fresp variable) and the
%       fitted frequency response ([h, w] = freqz( ... ) )
if p.plev >0
    
    % Combine PSDs into single variable for plotting
    data2plot=[];
    for i=1:n-1
        data2plot(:,i)=p.(['X' num2str(i)]); 
    end     
    
    % Append ideal frequency response
    data2plot(:, end+1)=fresp; 
    
    % Append real frequency response
    [h, ~] = freqz(filt, 1, size(data2plot,1)); % Match the number of samples in ideal response
    data2plot(:, end+1) = db(abs(h)); % convert to dB
    
    % Append estimate
    % Plot frequency response of all data series 
    dseries=char([repmat('X', n-1, 1) num2str((1:n-1)')], 'Filter (Ideal)', 'Filter (Real)');
    lineplot2d(f, data2plot , ...
        'linewidth', 1.5, ...
        'xlabel', 'Frequency (Hz)', ...
        'ylabel', 'PSD (dB/Hz)', ...
        'legend', {{dseries}}, ...
        'title', 'PSD Functions'); 
end % if p.plev > 0