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
%   1) Playback files are being added on the last trial, but the last trial
%   may satisfy the criteria we need. If the criteria are satisfied by the
%   END of the trial, then we don't want to add stimuli. If they are NOT
%   satisfied, then we need to add stimuli. But we won't know if the player
%   is in an exit state (all stimuli satisfied) until the last trial is
%   over. CWB recommends having multiple locations for modifiers to run. 
%
%       - Actually, the added playlists are NOT being added to the UsedList
%       data structure. Whoops! Still a problem, just of a different
%       nature.
%
%       - Maybe we can append the files to the playback list, gather the
%       list information, then (perhaps) wait until the NEXT trial to see
%       if we actually present the data.
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
    d.player.modifier{modifier_num}.initialized = true;
    
    % Initialize an "stimuli_appended" flag that will be used below to
    % track whether or not we've appended stimuli to the playback list.
    % Safe to assume we aren't appending stimuli out of the gate. 
    d.player.modifier{modifier_num}.stimuli_appended = false; 
    
    % Also track which trial number we appended stimuli during. We'll use
    % this below to track whether or not we have progressed beyond the
    % first stimulus of the appended playlist.
    d.player.modifier{modifier_num}.append_at_trial = [];
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

%% EXTEND PLAYBACK LIST
%   The playback list will be extended here as a precaution, but we won't
%   actually append the list to the "UsedList" data structure until after
%   the first trial of the appended files have been presented. 
if trial == numel(d.sandbox.playback_list);
    
    % Tell user we're adding stimuli
    cprintf('blue', 'Adding stimuli to playback list and loading them.'); 
    
    opts = d; 
    opts.specific.genPlaylist = d.player.modifier{modifier_num};
    opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'fhandle');
    opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'initialized');
    opts.specific.genPlaylist.Append2UsedList = false;    
    [playlist, used_lists] = SIN_getPlaylist(opts); 

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
    
    % Set a flag to let CWB know that files have been appended. Store this
    % in the modifier.
    d.player.modifier{modifier_num}.stimuli_appended = true; 
    
    % Also track which trial number we were at when we last appended
    % stimuli to the playback list
    d.player.modifier{modifier_num}.append_at_trial(end+1) = trial; 
    
    % Track the lists that were appended.
    d.player.modifier{modifier_num}.used_lists = used_lists;
    
    % Also track the appended files
    d.player.modifier{modifier_num}.appended_files = playlist; 
    
end % if ...

%% IF FIRST FILE IN PLAYLIST IS PRESENTED
%   If we are presenting the first stimulus in the appended stimulus train,
%   then append the list to the subject's used list data structure. 
if d.player.modifier{modifier_num}.stimuli_appended && (trial == d.player.modifier{modifier_num}.append_at_trial(end) + 1) 
    
    % If the player is in the 'exit' state, then we want to ...
    %   1) Remove the appended files from the playback list (sort of
    %   wasteful and potentially dangerous ... might be better to leave
    %   them there)
    %   2) Do NOT append the list to the used list data structure
    if ~isequal(d.player.state, 'exit')
    
        % Construct a query to send to SIN_getPlaylist that will do the
        % list tracking for us.        
        opts = d; 
        opts.specific.genPlaylist = d.player.modifier{modifier_num};
        opts.specific.genPlaylist.lists = d.player.modifier{modifier_num}.used_lists; 
        opts.specific.genPlaylist.files = d.player.modifier{modifier_num}.appended_files; 
        opts.specific.genPlaylist.Append2UsedList = true; % hard code so we append the the used play list
        
        % Call getPlaylist
        %   This should 
        SIN_getPlaylist(opts);         
        
    end % if ~isequal(d.player.state, 'exit')

end % 