function [rec, fs] = SIN_review_recordings(results, varargin)
%% DESCRIPTION:
%
%   This routine uses a GUI to select and plot out recordings acquired
%   saved in a results structure from player_main.
%
% INPUT:
%
%   results:    a results structure from player_main or SIN_runTest.
%
% Parameters:
%
%   assign_to_workspace:    bool, if true, assigns the "rec" and "fs"
%                           variables in the base workspace. (default =
%                           false)
%
% OUTPUT:
%
%   rec:    matrix, recording for commandline plotting routines.
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

%% SELECT TEST STAGE
% Determine which level of results we want to look into
%   This is necessary for multi-stage tests ... which is almost all tests
%   at this point
description = {};
for i=1:numel(results)
    description{i} = results(i).RunTime.specific.testID;
end % for i=1:numel

% Gather selection
[~, test_index] = SIN_select(description, 'title', 'Stage Selection', 'prompt', 'Select Test Stage');

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
    [~, rec_index] = SIN_select(description, 'title', 'Recording Selection', 'prompt', 'Select the Recording Number'); 
else
    error('No recordings found');
end % 

% Get the recording
rec = results(test_index).RunTime.sandbox.mic_recording{rec_index}; 

% Get the sampling rate
fs = results(test_index).RunTime.player.record.fs;

%% PLOTTING FUNCTION
plot_waveform(rec, fs, [], 2); 

if d.assign_to_workspace
    assignin('base', 'recording', rec);
    assignin('base', 'recording_fs', fs); 
end % if d.assign_to_workspace