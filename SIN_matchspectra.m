function [Pxx, Pyy, Pyyo, Y, Yo, FS, dPyy]=SIN_matchspectra(X, Y, varargin)
%% DESCRIPTION:
%
%   This function is designed to create a frequency domain filter to match
%   the long-term power spectra between two time series. This is done using
%   a spectral estimator (pwelch, currently). Consequently, it's important
%   that the user understand that this function is not intended to estimate
%   and correct for an impulse response. Also, the function disregards
%   phase altogether, which is another reason this function should not be
%   used to estimate or correct a speaker's transfer function. 
%
%   The function will accept several data types as an input (see
%   SIN_loaddata for more information) and allows the user to specify many
%   of the parameters. Many of these parameters (e.g., window, nfft, etc.)
%   will ultimately affect the estimated power spectral densities (PSDs)
%   and subsequently the corrections applied. 
%
%   Here's a brief overview of what this function does to estimate and
%   match long-term spectra between two time series. 
%
%       1. Ensure that the sampling rates are identical. If they are not,
%       the lower sampling rate is resampled to the highest sampling rate.
%       Routine will use 'resample'.
%
%       2. The power spectral densities (PSDs) are estimated prior to
%       zero-padding. CWB reasoned that zero-padding prior to PSD
%       estimation could lead to underestimated PSD values (due to adding
%       segments with no signal into the average), so opted to leave
%       zero-padding until later. 
%
%       3. Compute PSD differences. Differences are only computed over a
%       specific frequency range if the user specifies this. Otherwise, the
%       entire frequency range is corrected. 
%       
%       4. Zero-pad signals to same length
%
%       5. Apply correction to *unnormalized* FFT of signal. 
%
%       6. Inverse FFT to get back to time domain. Only real components are
%       used, since often times ifft will decide there are residual
%       imaginary values (on the order of 10E-16) and can typically be
%       safely ignored. See below for further discussion
%           http://www.dsprelated.com/showmessage/122422/1.php
%
% INPUT:
%
%   X:  The reference signal that all other time series are matched to. The
%       format can be anything supported by SIN_loaddata. This includes wav
%       files or two-dimensional matrices with double or single precision.
%       See SIN_loaddata for further information. 
%
%   Y:  Time series to match to X.
%
%   Additional Parameters:
%
%       'fsx':  sampling rate of time series X. Only used if X is not read
%               from file.
%
%       'fsy':  sampling rate of all time series in Y. Note that function
%               assumes an identical sampling rate across all time series
%               in Y. Only required if Y is a data matrix. Otherwise
%               ignored.
%
%       'mtype':    string, match type. Will match power, phase, or both. 
%                   ('power' | 'phase' | 'both') (default = 'power')
%                       Note: currently only tested with 'power'. Phase is
%                       not developed and probably isn't terribly useful in
%                       this context. 
%       
%       'plev': 	bool, creates summary plots for visualization.
%                   (true or false; default=true); 
%
%       'frange':   frequency range over which to do spectral matching
%                   (default = [-Inf Inf])
%
%       'window':   the window used for spectral estimation. If this is an
%                   integer value, then we assume this is the time (in sec)
%                   of a window. For instance, if window = 1, then we
%                   compute spectra in 1 sec windows. (default=[]; so
%                   whatever the spectral estimator's default is)
%
%       'noverlap': number of samples of overlap between sequential
%                   spectral estimates. (default=[]; so whatever the
%                   spectral estimator uses).
%   
%       'nfft':     integer value, the number of frequency bins to use in
%                   spectral estimation. For our *specific* purposes, this
%                   must be at *least* the length of the longest, resampled
%                   time signal. Otherwise the spectral estimation and
%                   matching won't work properly.
%       
%       'write':    bool, write data to file. Data are written to WAV
%                   files. (true | false | default=false) 
%
%       'yminmax':  two-element double array, describes range of y-values.
%                   (E.g. [-1 1]). Default = [-1 1]. If these values are
%                   exceeded in any series in Y, all data are scaled to
%                   0.98 of the maximum (or minimum) range. 
%
%       'taper':    XXX something to taper beginning and end of sounds XXX
%                       - Not implemented (no need at time of testing).                    
%
% OUTPUT:
%   
%   Pxx:    Power spectral density of X series (in dB).
%
%   Pyy:    Power spectral density of Y (input) series (in dB).
%
%   Pyyo:   PSD of *corrected* Y series (corresponds to Yo return). (dB).
%
%   Y:      Input time series.
%
%   Yo:     Output time series. Can be written to file
%
%   FS:     Sampling rate of all return variables.
%
%   Development:
%       Currently the plotting routines require recomputing power spectral
%       density. Slow. Could be done in a smarter way, says CWB, and will
%       probably save considerable computation time with long time series. 
%
%   Tests:
%       Run with the same sound file as X and Y. Shouldn't see any
%       difference in the spectra (no adjustments applied). 
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

%% LOAD DATA
%   Load data using SIN_loaddata. AD_matchspectrum currently only tested
%   with WAV files, but should be easily expandable to support EEG/ERP
%   structures or other time series data.
p.datatype=[2]; % currently only allow user to use a WAV file.
[X, FSx]=SIN_loaddata(X, p); 
[Y, FSy, LABELS]=SIN_loaddata(Y, p); 

%% USER DEFINED SAMPLING RATE
%   In the event that SIN_loaddata can't determine the sampling rate, we'll
%   need to assign what the user provides us. 
%       XXX undeveloped XXX

%% MATCH SAMPLING RATE
%   Sampling rates must be matched between time series for frequency domain
%   filtering and spectral estimation. 
%       Currently, the time series with the lower sampling rate is
%       upsampled to match the higher(est) sampling rate. 
%
%       Data are later resampled back to their original sampling rates.
FS=max([FSx FSy]); % sampling rate for all stimuli
X=resample(X, FS, FSx); % resample X
Y=resample(Y, FS, FSy); % resample Y

% What is our longest data series?
mxl = max([length(X) length(Y)]);

%% INPUT CHECK AND DEFAULTS
%   Set some default values.
if ~isfield(p, 'mtype') || isempty(p.mtype), p.mtype='power'; end 
if ~isfield(p, 'nfft') || isempty(p.nfft); p.nfft=mxl; end 
if p.nfft<mxl, error(['nfft must be at least at least as long as your longest signal (' num2str(mxl) ' samples)']); end 
try p.plev; catch p.plev=true; end % plot output by default
try p.frange; catch p.frange=[-Inf Inf]; end % adjust whole frequency range by default
try p.window; catch p.window=[]; end % use default windowing option
try p.noverlap; catch p.noverlap=[]; end % use default noverlap
try p.write; catch p.write=false; end % write data to wav file
try p.yminmax; catch p.yminmax=[-1 1]; end % p.yminmax

% Convert p.window from seconds to samples
if ~isempty(p.window) && numel(p.window)==1
    p.window=p.window*FS;
end % if ~isempty(p.window) && numel(p.window)==1

%% COMPUTE PSD
%   Power spectral densities (PSDs) are estimated for the reference time
%   series (X) and all other time series (Y). Spectral estimators, such as
%   pwelch, provide better (less noisy) spectral estimates, but may suffer
%   from bias if the user provides wonky inputs. A few notes:
%
%       1) Bias in spectral estimation is often introduced if the time
%       window is too short. CWB is not aware of any specific guidelines on
%       window selection with pwelch (currently supported estimator), but
%       there are other, potentially adaptive window tapering protocolots
%       (see pmtm.m for an example or 'doc spectrum' for more information)
%
%       2) It's not (yet) crucial for the two time series to match in
%       length. This is due to the algorithm employs for spectral
%       estimation (a periodogram - essentially an average spectrum over
%       several time windows). 
%
%       3) We use PSDs because the normalization procedure accounts for
%       differences in frequency bin size (crudely "resolution"). Power
%       spectra (not densities) do not and thus preclude direct comparisons
%       of normalized FFTs of signals of varying length (sample number). 
%           For further discussion on this, see 
%               http://qsun.eng.ua.edu/cpw_web_new/generic1.htm
%
%       4) We compute a two-sided PSD for computational ease below - the
%       FFTs required below are necessarily two-sided by default.
[Pxx, F]=pwelch(X, p.window, p.noverlap, p.nfft, FS, 'twosided'); 

% Get frequency mask
fmask=SIN_maskdomain(F, p.frange);

% Initialize Pyy with NaN
%   Easier to spot screw ups this way 
Pyy=nan(length(F), size(Y,2)); 
for t=1:size(Y,2)
    pyy=pwelch(Y(:,t), p.window, p.noverlap, p.nfft, FS, 'twosided'); 
    Pyy(:,t)=pyy;
    clear pyy; 
end % for t=1:size(Y,2)

%% CONVERT Pxx and Pyy to DECIBELS
Pxx=db(Pxx, 'power');
Pyy=db(Pyy, 'power'); 

%% MEAN CENTER Pxx and Pyy
%   Mean centering allows us to correct the shape of the spectrum while not
%   making any effor to match overall levels.
%       Should mean centering happen over the user-specified frequency
%       range? CWB thinks so ...
% Pxx(fmask)=Pxx(fmask)-mean(Pxx(fmask));
% Pyy(fmask,:)=Pyy(fmask,:)-ones(length(fmask),1)*mean(Pyy,1); 

%% COMPUTE DIFFERENCES IN PSDs
%   Compute differences in PSDs between reference time series (X) and other
%   time series (Y).
dPyy=Pxx*ones(1,size(Y,2))-Pyy; % compute difference (in dB)

%% FFT OF TIME SERIES
%
%   Frequency decomposition of the signal. Signals must be the same number
%   of samples. Zero padding necessary, but should be taken care of
%   implicitly in call to FFT.
%
%   Notice that the FFT output is *not* normalized (divided by nfft). This 
%   is what we want. Normalizing a zero padded signal causes issues when
%   comparing spectra.
%
%       To illustrate, take an FFT of a signal. Now take an FFT of the same
%       signal but with zero padding - pad to twice the stimulus length.
%       Comparing the shared frequency bins between the two unnormalized
%       FFTs will give you *exactly* the same values. BUT, after
%       normalizing, these data will differ by a factor of 1/2 (~6 dB in
%       amplitude). So we want to operate on things BEFORE we normalize.
%
%       For further discussion see 
%           https://www.evernote.com/shard/s353/nl/57578676/14146ec7-588f-495c-953b-cf45abeae451
ffty=fft(Y, p.nfft); % column wise FFT
pow=db(abs(ffty).^2, 'power'); % power (in dB); equivalently db(abs(fftx)), I think
ang=angle(ffty); % phase angle

%% APPLY POWER ADJUSTMENTS
% Apply adjustments over specified frequency range
pow(fmask)=pow(fmask)+dPyy(fmask); 

%% CONVERT TO MAGNITUDE
%   Convert back to magnitude
pow=db2amp(pow); % XXX CWB SHOULD CHECK XXX

%% RECONSTRUCT FFT
%   Put together (unchanged) phase and (potentially changed) magnitudes
ffto=pow.*cos(ang) + pow.*sin(ang).*1i; % multiple y by imaginary number

%% GO BACK TO TIME
%   Inverse FFT (ifft) to get back to the time domain
Yo=real(ifft(ffto)); % Sometimes Yo is returning total nonsense (complex values). Not sure why ... maybe just grab the "real" part of it??
clear ffto; 

%% CLIP TIME SERIES
%   Reduce time series to original length (before any zero-padding).
Yo=Yo(1:size(Y,1),:); 

%% APPLY RAMP
%   Potentially apply windowing function at beginning/end of sounds to
%   prevent any popping introduced through filtering. 
%       XXX CWB Has not had a need for this yet, so it isn't implemented
%       XXX

%% RESAMPLE SOUNDS
%   Should we resample time series to original sampling rate? 
%   CWB thinks this is probably a bad idea anyway, so we don't do that for
%   now. 

%% GET Pyy OF INPUTS and Pyyo of OUTPUTS
%   We change a lot of this during processing, so better to get it again to
%   make sure we haven't biffed anything.

% Initialize Pyy with NaN
%   Easier to spot screw ups this way 
Pyy=nan(length(F), size(Y,2)); 
for t=1:size(Y,2)
    pyy=pwelch(Y(:,t), p.window, p.noverlap, p.nfft, FS, 'twosided'); 
    Pyy(:,t)=pyy;
    clear pyy; 
end % for t=1:size(Y,2)

%% PSD OF OUTPUTS
Pyyo=nan(length(F), size(Yo,2)); 
for t=1:size(Yo,2)
    pyyo=pwelch(Yo(:,t), p.window, p.noverlap, p.nfft, FS, 'twosided'); 
    Pyyo(:,t)=pyyo;
    clear pyyo; 
end % for t=1:size(Y,2)

%% REESTIMATE REFERENCE SERIES
[Pxx, F]=pwelch(X, p.window, p.noverlap, p.nfft, FS, 'twosided'); 

%% Convert to DECIBELS (dB)
Pxx=db(Pxx, 'power'); 
Pyy=db(Pyy, 'power'); 
Pyyo=db(Pyyo, 'power'); 

%% MEAN CENTER
%   Mean center to ease comparisons
%       Mean centering relative to selected frequencies will ensure that
%       all CORRECTED frequencies line up, but not necessarily frequencies
%       outside the analysis window. 
% Pxx=Pxx - mean(Pxx(fmask));
% Pyy=Pyy - mean(Pyy(fmask));
% Pyyo=Pyyo - mean(Pyyo(fmask));

%% CREATE PLOTS
%   Create plots for visualization if user so desires (p.plev>0)
if p.plev
    
    % Plot time waveforms
    %   Plot waveforms of time series before (Y) and after (Yo) spectrum
    %   matching.
    T=0:1/FS:(size(Y,1)-1)/FS; 
    T=SIN_loaddata(T, 'fs', FS);  % set correct dimensions
    lineplot2d(T, [Y Yo], 'legend', {{[LABELS{:} repmat(' (in)', size(Y,2),1)] [LABELS{:} repmat(' (out)', size(Yo,2),1)] }}, 'linewidth', 1.5, 'xlabel', 'Time (s)', 'ylabel', 'Amplitude (V)', 'title', 'Time Waveforms'); % opens a new figure
    
    % Plot PSDs (before)
    lineplot2d(F, [Pxx Pyy Pyyo], 'legend',{{'Reference' [LABELS{:} repmat(' (in)', size(Y,2),1)] [LABELS{:} repmat(' (out)', size(Yo,2),1)] }}, 'linewidth', 1.5, 'xlabel', 'Frequency (Hz)', 'ylabel', 'PSD (dB/Hz)', 'title', 'Power Spectral Densities');
    
    % Plot PSD differences
    %   Note that a mean difference isn't informative since we do not match
    %   levels here. 
    lineplot2d(F, [Pyyo - Pxx*ones(1, size(Pyyo,2))], 'legend', {{[LABELS{:} repmat(' (diff)', size(Y,2),1)] }}, 'linewidth', 1.5, 'xlabel', 'Frequency (Hz)', 'ylabel', 'dB/Hz', 'title', 'PSD Difference (Pxx - Pyyo)');
    
end % p.plev

%% WRITE DATA TO FILE
if p.write
    
    % write each time series to file
    for t=1:size(Yo,3)
        wavwrite(Yo(:,t), FS, [LABELS{t} '.wav']); 
    end % for t=1:size(Y,3)
    
end % p.write