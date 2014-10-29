function [file_names] = recordings_to_file(results, varargin)
%% DESCRIPTION:
%
%   This function accepts a results structure from player_main and writes
%   the recordings to file with the write parameters provided by the user.
%
%   Recordings are written to file in the .wav format at the sampling rate
%   used for the recordings during stimulus testing. 
%
% INPUT:
%
%   results:    results strcuture from SIN's player_main
%
% Parameters:
%
%   'bit_depth':    bit depth to use in written files
%
% OUTPUT:
%
%   file_names: cell array of file names for the output files. These will
%               contain the absolute path to the files.
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% PLACE PARAMETERS IN STRUCTURE
d=varargin2struct(varargin{:});  

% Loop through each test segment
for i=1:numel(results)
    
    % Retrive recordings
    recordings = results(i).RunTime.sandbox.mic_recording;
    
    % Retrieve playback file names
    playback_list = results(i).RunTime.sandbox.playback_list;
    
    % Safety check to make sure the number of playback files matches the
    % number of recordings
    if numel(playback_list) ~= numel(recordings), error('Dimensions do not match'); end
    
    % Retrieve recording sampling rate
    record_fs = results(i).RunTime.sandbox.record_fs;
    
    % Create directory 
    %   Need to create a top level directory for the test itself, then sub
    %   directories for each test segment. 
    
    % Break up UUID into file parts
    [PATHSTR, NAME, EXT] = fileparts(results(i).RunTime.specific.saveData2mat); 
    directory_name = fullfile(results(i).RunTime.subject.subjectDir, [NAME '_recordings']);
    
    if ~exist(directory_name, 'dir')
        mkdir(directory_name);
    end % if ~exist(directory_name ...
    
    % Make subdirectory
    directory_name = fullfile(directory_name, sprintf('Segment_%02d', i));
    if ~exist(directory_name, 'dir')
        mkdir(directory_name);
    end % if ~exist(directory_name ...
    
    % Loop through recordings and write to file
    for r=1:numel(recordings)
        
        % Break up playback file into file parts
        [PATHSTR, NAME, EXT] = fileparts(playback_list{r}); 
        
        % Create the output file name
        file_names{i}{r} = fullfile(directory_name, [results(i).RunTime.subject.subjectID '_' NAME '.wav']);
        
        % Write data to file
        audiowrite(file_names{i}{r}, recordings{r}, record_fs, 'BitsperSample', d.bit_depth); 
        
    end % for r=1:numel(recordings)
    
end % for i=1:numel(results)