function [recording, record_fs] = SIN_review_recordings(results, varargin)
%% DESCRIPTION:
%
%   This routine uses a GUI to select and plot out recordings acquired
%   saved in a results structure from player_main.
%
%   It will also ask the user if he/she wants to play back a portion of the
%   loaded file. Christi Miller mentioned that it would be useful to listen
%   to/quickly screen data as they are acquired. So, CWB expanded on this
%   routine to allow experimenters to playback all or a portion of the
%   file. 
%
% INPUT:
%
%   results:    a results structure from player_main or SIN_runTest.
%
% Parameters:
%
%   assign_to_workspace:    bool, if true, assigns the "recording" and "record_fs"
%                           variables in the base workspace. (default =
%                           false)
%
%   sound_playback: integer, determines if a sound will be played back in
%                   its entirety (1), not at all (0), or at a
%                   user-specified time window (2). If playback is set,
%                   then the user must also specify which channels to play
%                   from. (default = 0). This will only work if a single
%                   recording is selected. 
%
%   playback_channels:  array, channels to include in playback. This must
%                       contain 1 or 2 elements, no more. Playback achieved
%                       using audioplayer, which only accepts 1 and 2
%                       channel sounds. (default = 1:2)
%
% OUTPUT:
%
%   recording:  matrix, recording for commandline plotting routines.
%
%   record_fs:  sampling rate of recording     
%
% Development:
%
%   None (yet).
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% DEFAULT
if ~isfield(d, 'assign_to_workspace') || isempty(d.assign_to_workspace), d.assign_to_workspace = false; end
if ~isfield(d, 'sound_playback') || isempty(d.sound_playback), d.sound_playback = 0; end % Don't play sound back by default
if ~isfield(d, 'playback_channels') || isempty(d.playback_channels), d.playback_channels = 1:2; end % Don't play sound back by default

%% SELECT TEST STAGE
% Determine which level of results we want to look into
%   This is necessary for multi-stage tests ... which is almost all tests
%   at this point
description = {};
for i=1:numel(results)
    description{i} = results(i).RunTime.specific.testID;
end % for i=1:numel

% Gather selection
[~, test_index] = SIN_select(description, 'title', 'Stage Selection', 'prompt', 'Select Test Stage', 'max_selections', 1);

%% GET RECORDING NUMBER
%   There's gotta be a way to vectorize this, but I can't figure out how.
%   This is faster than me digging through the interwebs. 
number_of_recordings = numel(results(test_index).RunTime.sandbox.mic_recording);
description = {};
for i=1:number_of_recordings
    description{i} = ['Recording ' num2str(i) ];
end % for i=1:number ...

% Will only work if there are recordings 
if ~isempty(description)
    [~, rec_index] = SIN_select(description, 'title', 'Recording Selection', 'prompt', 'Select the Recording Number', 'max_selections', -1); 
else
    error('No recordings found');
end % 

% Get the recording
recording = {results(test_index).RunTime.sandbox.mic_recording{rec_index}}; 

% Get the sampling rate
record_fs = results(test_index).RunTime.sandbox.record_fs;

%% PLOTTING FUNCTION
% for i=1:numel(recording)
    
plot_waveform(recording, record_fs, [], 2, [], 'grid', true); 

if d.assign_to_workspace
    assignin('base', 'recording', recording);
    assignin('base', 'recording_fs', record_fs); 
end % if d.assign_to_workspace

%% PLAYBACK PROMPT
%   Case 0 does not play the sound back at all. 
switch d.sound_playback    
    
    case 1
        
        % Play the whole recording from start to finish.
        playback_window = 1:size(recording{1},1);
        
    case 2
        playback_select = inputdlg({'Select starting time (sec)', ...
            'Select end time (sec)'}, 'Select playback window', ...
            2, ...
            {'0', num2str(size(recording{1},1)/record_fs)});
        
        % Convert to a playback window
        playback_window = ceil(1 + str2double(playback_select{1})*record_fs):floor(1 + str2double(playback_select{2})*record_fs);
        
end % switch

%% PLAYBACK RESTRICTIONS
%   Only playback if we've selected a single recording (1 cell).
if length(recording) > 1 && d.sound_playback ~= 0
    warning('Playback limited to first selected recording');     
end % 

% Play the recording
%   Assume we are only playing the first recording if multiple recordings
%   are selected. 
if d.sound_playback ~= 0
    ap = audioplayer(recording{1}(playback_window,d.playback_channels), record_fs); 
    ap.play();
end % d.sound_playback ~= 0
