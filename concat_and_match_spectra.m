function [YtoX] = concat_and_match_spectra(X, Y, varargin)
%% DESCRIPTION:
%
%   This is essentially a wrapper function for SIN_matchspectra. While
%   SIN_matchspectra will only accept a single file for X and Y
%   (generally), this function will accept cell arrays for X and Y, and
%   create concatenated time series for use in spectral matching. 
%
%   This specific scenario proved useful when spectrally matching speech
%   shaped noise (SPSHN) to the long-term average of multiple audio files. 
%
% INPUT:
%
%   X:  cell array, where each element is a to-be-concatenated (single
%       channel) time series or the path to a file on disk that can be
%       loaded with SIN_loaddata.m.
%
%       X is the reference time series - that is, the spectrum we are
%       trying to match.
%
%   Y:  similar to Y, but the spectrum of this sound will be matched to X.
%
% Parameters:
%
%   File loading:
%   
%   'xmixer':   Dx1 matrix, where D is the number of channels present in
%               the data series loaded from disk. Must ultimately be 1
%               channel to work with SIN_matchspectra.
%
%   'ymixer':   Dx1 matrix, just like xmixer, but for Y series. 
%               
%   Spectral matching (additional inputs for SIN_matchspectra)
%
%   'plev': 	bool, creates summary plots for visualization.
%                   (true or false; default=true); 
%
%   'frange':   frequency range over which to do spectral matching
%               (default = [-Inf Inf])
%
%   'window':   the window used for spectral estimation. If this is an
%               integer value, then we assume this is the time (in sec)
%               of a window. For instance, if window = 1, then we
%               compute spectra in 1 sec windows. (default=[]; so
%               whatever the spectral estimator's default is)
% 
%   'noverlap': number of samples of overlap between sequential
%               spectral estimates. (default=[]; so whatever the
%               spectral estimator uses).
% 
%   'nfft':     integer, number of frequency bins in FFT. Must be at
%               least as large as the number of samples in the longest
%               signal in the series (X or Y). 
%
% OUTPUT:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   9/14

%% LOAD PARAMETERS
d=varargin2struct(varargin{:});

%% LOAD X SERIES
Xseries = [];
fsx= [];
for i=1:numel(X)
    
    % Load data
    [xt, fs] = SIN_loaddata(X{i}); 
    
    % Apply mixer
%     xt = remixaudio(xt, 'mixer', d.xmixer); 
    
    % Assign to fsx
    if isempty(fsx)
        fsx = fs;
    elseif fsx ~= fs
        error('Sampling rates do not match'); 
    end % if isempty(fsx)    
        
    % Add new time series to concatenated time series
    Xseries = [Xseries; xt]; %#ok<AGROW>
end % for i=1:numel(X)

% Apply mixer to create a single channel for X
Xseries = remixaudio(Xseries, 'mixer', d.xmixer, 'fsx', fsx, 'writetofile', false); 

%% LOAD Y SERIES
Yseries = [];
fsy= [];
for i=1:numel(Y)
    
    % Load data
    [yt, fs] = SIN_loaddata(Y{i}); 
    
    % Apply mixer
%     yt = remixaudio(yt, 'mixer', d.ymixer); 
    
    % Assign to fsx
    if isempty(fsy)
        fsy = fs;
    elseif fsy ~= fs
        error('Sampling rates do not match'); 
    end % if isempty(fsx)    
        
    % Add new time series to concatenated time series
    Yseries = [Yseries; yt]; %#ok<AGROW>
    
end % for i=1:numel(X)

% Apply mixer to create a single channel for Y
Yseries = remixaudio(Yseries, 'mixer', d.ymixer, 'fsx', fsy, 'writetofile', false);  % yes, this read 'fsx'. That's OK 

%% NOW MATCH SPECTRA
%   This procedure is wildly inefficient, but (more or less) functional. 
[Pxx, Pyy, Pyyo, Y, YtoX, FS]=SIN_matchspectra(Xseries, Yseries, 'fsx', fsx, 'fsy', fsy, 'window', d.window, 'noverlap', d.noverlap, 'nfft', d.nfft, 'plev', d.plev, 'frange', d.frange, 'write', false);