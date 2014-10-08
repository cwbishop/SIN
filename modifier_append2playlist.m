function [Y, d] = modifier_append2playlist(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Appends new playback data to the playback list in player_main. This
%   proved useful when using adaptive algorithms (e.g., 3down1up for
%   SNR-80 estimation) that may require more stimuli than originally
%   specified by the user.
%
%   This essentially just calls SIN_getPlaylist with the user-provided
%   settings as written the SIN options structure. These values are then
%   appended to the 'stim' variable in player_main. 
%
%   Note: This function intentionally ignores values in the "files" field
%   of specific.genPlaylist. The assumption is that we're looking for a
%   *new* playlist to append to the playback list in player_main
%
% INPUT:
%
%   X:  data time series (unmodified here)
%
%   mod_code:   modifier code (unused here)
%
%   opts:   options structure from player_main.
%
% Parameters:
%
% Parameters used in call to SIN_getPlaylist:
%
%   See SIN_getPlaylist for more details on each of these input parameters.
%
%   'UsedList': path to used list file.
%
%   'NLists':   number of lists to append
%
%   'Randomize':    randomization parameter for SSIN_getPlaylist
%
%   'Repeats':  specifies how repeated lists/stimuli are handled during
%               list selection
%
%   'Append2UsedList':  bool, appends list information to used list data
%                       structure. CWB highly recommends setting this to
%                       true. 
%
%   'files':    cell array of file names. CWB highly recommends this be set
%               to an empty cell array since SIN_getPlaylist will not
%               select a new playlist if files is set. 
%
% OUTPUT:
%
%   Y:  unaltered data time series
%
%   d:  updated options structure
%
% Development:
%
%   Parameters
%
% Christopher W Bishop
%   University of Washington
%   10/14


d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

%% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% ASSIGN RETURN DATA
%   This function does not alter the data directly, so just spit back the
%   original data
Y=X; 

%% IF THIS IS OUR FIRST CALL, JUST INITIALIZE 
%   - No modifications necessary, just return the data structures and
%   original time series.
if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

% Make options structure for playlist creation
if trial == numel(d.sandbox.playback_list);
    
    opts = d; 
    opts.specific.genPlaylist = d.player.modifier{modifier_num};
    opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'fhandle');
    opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'initialized');

    playlist = SIN_getPlaylist(opts); 

    % Append playlist to existing playlist
    d.sandbox.playback_list = {d.sandbox.playback_list{:} playlist{:}}';

    % If stimuli are preloaded in player_main then we need to load the stimuli
    % and resample them before appending them to the existing stim array. 
    if d.player.preload
         stim2append = {};
        for i=1:numel(playlist)
            [stim2append{i}, fs] = SIN_loaddata(playlist{i}); 
            stim2append{i} = resample(stim2append{i}, d.sandbox.playback_fs, fs); 
        end % for i=1:numel(playlist) 

        assignin('caller', 'stim2append', stim2append); 
        evalin('caller', 'stim = {stim{:} stim2append{:}};');
        evalin('caller', 'clear stim2append'); 

    end % if d.player.preload 

end % if ...