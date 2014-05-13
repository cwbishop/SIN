function [D, FS]=Hagerman_getsignal(X, Y, varargin)
%% DESCRIPTION:
%
%   Function to extract a signal from a pair of (phase inverted) Hagerman
%   recordings. 
%
%   The non-phase inverted signal is returned along with its samppling 
%   rate. 
%
%   Note that the function assumes that the data are already time aligned.
%   If this is not the case, then call align_timeseries.m before calling
%   Hagerman_getsignal.m. If the signals are not temporally aligned, the
%   output will be meaningless. 
%
% INPUT:
%
%   X:  time series 1. This can either be a single/double matrix (time
%       series) or a string with the path information to a single-channel
%       wav file. Data are loaded via AA_loaddata; see AA_loaddata for more
%       information and potential for extending support to other file
%       types.
%
%   Y:  time series 2. Same as X, but with inverted playback/recording. 
%
%       Note: The order of X and Y does not matter; the return variable, D,
%       will be precisely the same.
%
% Parameters:
%
%       'fsx':  double, sampling rate for X time series. Required if X is a
%               time series instead of a path string. 
%
%       'fsy':  " ", but for Y time series. Required if Y is a time series
%               instead of a path string.
%
%       'pflag':    integer, plotting flag. 
%                       0:  do not generate plots (default)
%                       >0: generate plots
%
% OUTPUT:
%
%   D:  double, time series of extracted signal. 
%
%   FS: samping rate of D. 
%
% Development:
%
%   1. Add flags to perform realignment in call to Hagerman_getsignal.
%   2. Include resampling routine if sampling rates of two time series do
%      not match.
%
% Christopher W. Bishop
%   University of Washington
%   5/14

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

%% INPUT CHECKS AND DEFAULTS

%% LOAD DATA
%   Limit to one data series for X and Y. 
%   Allow WAV and single/double information. 
t.maxts=1; 
t.datatype=[1 2];
if isfield(p, 'fsx') && ~isempty(p.fsx), t.fs=p.fsx; end 
[X, fsx]=AA_loaddata(X, t); 

if isfield(p, 'fsy') && ~isempty(p.fsy), t.fs=p.fsy; end 
[Y, fsy]=AA_loaddata(Y, t); 

clear t; 

%% SAMPLE RATE CHECK
%   For now, if the sample rates are not equal, throw an error. We don't
%   want data recorded at variable sampling rates being compared. 
%
%   Ultimately, this can probably be addressed by resampling to the higher
%   of the two sampling rates.
if fsx~=fsy
    error('Sample rates do not match. No compensatory routines in place. Contact cwbishop@uw.edu.'); 
else 
    % If the two sample rates are equal, then set FS to fsx. Easier to work
    % with later. 
    %
    % Also a place holder in the event that CWB implements a resampling
    % procedure later - shouldn't introduce a bug this way. 
    FS=fsx; 
end % if fsx~=fsy 

%% LENGTH CHECK
%   If the time series are not the same length, then the calcs below will
%   throw a shoe. Put in a check to give some informative feedback. 
if size(X,1) ~= size(Y,1)
    error('Time series are different lengths');
end % if size(X,1) ~= size(Y,1); 

%% EXTRACT SIGNAL
%   Equation goes as follows if these are paired, phase inverted
%   recordings.
%
%   Signal= (X + Y)/2
D=(X+Y)/2;

%% PLOTTING ROUTINES
%   Plot out data for visualization
if p.pflag>0
    
    % Create time vector for plotting purposes
    T=0:1/FS:(size(X,1)-1)/FS;
    
    %% CREATE 2D LINE PLOT
    lineplot2d(T, [X Y D], 'linewidth', 1, 'xlabel', 'Time (s)', 'ylabel', 'Units', 'title', 'Hagerman Estimated Signal', 'linestyle', '-', 'legend', {{'X (orig)' 'Y (orig)' 'Signal' }}, 'legend_position', 'EastOutside'); % opens a new figure 
    
end % if p.pflag