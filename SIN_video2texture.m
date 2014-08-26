function [textures, runtime] = SIN_video2texture(X, varargin)
%% DESCRIPTION:
%
%   Function to convert videos to textures. This requires PsychToolBox-3,
%   MATLAB's VideoReader and audioread functions.
%
% INPUT:
%
%   X:  list of file names (typically MP4s for SIN) to load. 
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   textures:   N-element cell array, where N is the number of videos being
%               loaded/converted to textures. 
%
%               Perhaps an alternative input option with a cell array of 4D
%               images? This would be conceptually similar to passing in
%               many movies at once, all of which need to be memory mapped.
%               Could save time in loading data. 
%
% Development:
%
%   window:     handle to PTB window. Necessary for conversion. If window
%               is not provided, then SIN will open a new window and do it
%               that way. That'll cause some display interruption. 
%
% Christopher W. Bishop
%   University of Washington
%   8/14

%% LOAD INPUT PARAMETERS
%   Loads key/value pairs as structure
d=varargin2struct(varargin{:}); 

%% LOAD DATA
%   Load MP4s one at a time, map to texture
texture = []; % empty texture index

%% OPEN A NEW WINDOW?
%   If we weren't provided with a window index, then we need to make a
%   window of our own.
if ~isfield(d, 'window') || isempty(d.window)
    whichScreen=max(Screen('Screens'));
    [window,screenRect] = Screen('OpenWindow',whichScreen);
    d.window = window;     
end % if ~isfield(d ...

%% LOAD VIDEOS, MAP TO TEXTURES
textures = cell(numel(X), 1); % preallocate
for i=1:numel(X)
    start = GetSecs;
    % Load the audio and video information first
%     av = SIN_loaddata(X{i}); 
    avObj = VideoReader(X{i});
    vid = read(avObj); 
%     vid = av.vid; 
    
    % Map to texture in window
    tindex = nan(size(vid,4),1); % preallocate, set to NaN
    for n=1:size(vid,4) 
        
        tindex(n) = Screen( 'MakeTexture', d.window, vid(:,:,:,i) );
        
    end % for n=1:
    
    % Now copy tindex over to a cell array
    textures{i} = tindex;
    
    runtime = GetSecs - start
    % Clear variables
    clear tindex av vid; 
    
end % for i=1:numel(X)

% Close window?
%   Probably don't want to do this since it might destroy the textures.
Screen('CloseAll');