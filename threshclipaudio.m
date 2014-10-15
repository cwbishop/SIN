function [time_series_clip, clip_mask] = threshclipaudio(time_series, amplitude_threshold, clip_mode, varargin)
%% DESCRIPTION:
%
%   Function designed to remove silent periods from beginning and end of a
%   sound file. To do this, the code removes all samples preceding the
%   first sample that exceeds the provided (absolute) amplitude threshold.
%
%   The end is clipped such that all samples following the last sample that
%   meets or exceeds the provided amplitude threshold are discarded.
%
% INPUT:
%
%   time_series:   Nx1 data series, where N is the number of samples and 1 is the
%           number of channels. Note that this function is NOT designed to
%           work with multichannel data. 
%
%   amplitude_threshold:  double, absolute amplitude threshold to apply.
%
%   clip_mode:  character, mode of operation.
%
%               'begin':    clip just the beginning
%               'end':      clip just the end
%               'begin&end':    clip beginning and end
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   time_series_clip:   time series with leading and lagging data points
%                       removed
%
%   clip_mask:  logical vector of lenght time_series. An element is true if
%               the sample was removed (clipped). An element is false if
%               the sample was not removed (that is, the amplitude exceeded
%               the specified threshold).
%
% Christopher W. Bishop
%   University of Washington 
%   9/14, Revision 10/14

%% INPUT CHECK

% Check data dimensions
time_series = SIN_loaddata(time_series, 'fs', 0); 

% Throw error if incorrect number of channels provided
if size(time_series,2) ~= 1, error('Incorrect number of channels'); end 

% This is a logical vector that is *true* for values
clip_mask_begin = false(size(time_series)); 
clip_mask_end = false(size(time_series)); 

%% CLIP BEGINNING
%   Here, we remove all values from the beginning of the time series that
%   do not exceed the provided amplitude value 
if ~isempty(strfind(clip_mode, 'begin'))
    
    % Find first sample that meets or exceeds threshold
    ind = find(abs(time_series)>=amplitude_threshold, 1, 'first'); 
    
    % Set the clipping mask
    clip_mask_begin(1:ind-1,:) = true;
    
    % Mask the data
%     time_series_clip = time_series(~clip_mask_begin);     
    
end % if ~isempty(mode, 'begin') 

%% CLIP END
%
%   Here, we remove all values from the end of the stimulus that do not
%   exceed the provided amplitude value. This is done by temporally
%   reversing the signal and making a recursive call to threshclipaudio. 
if ~isempty(strfind(clip_mode, 'end'))
    
    % Flip signal, then recursive call
    [time_series_clip, clip_mask_end] = threshclipaudio(flipud(time_series), amplitude_threshold, 'begin');
    
    % Now flip it back
    time_series_clip = flipud(time_series_clip); 
    
    % Also flip the logical mask
    clip_mask_end = flipud(clip_mask_end); 
    
end % if ~isempty(strfind(mode, 'end')

% Create joint logical clipping mask
clip_mask = clip_mask_begin | clip_mask_end;

% Mask the time series
time_series_clip = time_series(~clip_mask); 