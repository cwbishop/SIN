function [concat, fs] = concat_audio_files(audio_files, varargin)
%% DESCRIPTION:
%
%   This function will load and concatenate all audio files. Parameters
%   below apply some control over stimulus processing (e.g., trimming
%   silence from beginning and end of sound, etc.). 
%
% INPUT:
%
%   audio_files:    cell array of file names. All files should have the
%                   same sampling rate and the same number of channels
%
%                   Alternatively, this can be a cell array of time series.
%                   If this is the case, then each time series will be
%                   assumed to have the same sampling rate and number of
%                   channels. 
%
% Parameters:
%
%   'fs':   sampling rate. Only required if audio_files is a cell array of
%           time series. 
%
%   'remove_silence':   bool, if set, silence at beginning and end of
%                       sounds will be removed before concatenating files.
%                       If this is set to TRUE, then amp_thresh must be
%                       defined below as well. 
%
%   'amplitude_threshold':  double, this is the amplitude threshold used to
%                           determine what is "silence" and what is not.
%                           Anything smaller than this value will be
%                           considered silence. 
%
%   'mixer':    Dx1 mixing matrix. Some of the helper functions require
%               single channel inputs, so the mixer may need to be put in
%               line to collapse the data into a single channel. 
%
% OUTPUT:
%
%   concat: concatenated time series.
%
%   fs:     sampling rate of concatenated time series.
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

%% DEFINE OUTPUT PARAMETERS
concat = [];
fs = []; 

% Load each file, remove silence if necessary
for i=1:numel(audio_files)
    
    % We pass in d as a paramter list so SIN_loaddata can have access to
    % the sampling rate information if it exists. 
    [time_series, tfs] = SIN_loaddata(audio_files{i}, d); 
    
    % Apply mixer to time_series
    time_series = time_series*d.mixer; 
    
    % Sampling rate check 
    if isempty(fs)
        fs = tfs;
    elseif tfs ~= fs
        error('Sampling rates do not match');
    end % if isempty(fs)
    
    % Remove silence if user tells us to
    if d.remove_silence
        time_series = threshclipaudio(time_series, d.amplitude_threshold, 'begin&end'); 
    end % if d.remove_silence
    
    % Concatenate time series
    concat = [concat; time_series];
    
end % for i=1:numel(audio_files)