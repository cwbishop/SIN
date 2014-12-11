function wordspan_rename_files(varargin)
%% DESCRIPTION:
%
%   Renames all files used for word span. 
%
% INPUT:
%
% Parameters:
%   
%   'delete_old':   bool, if true, then old files are deleted. If false,
%                   old files are left alone.
%
% OUTPUT:
%
%   Rewritten files
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GET INPUT OPTIONS
d = varargin2struct(varargin{:});

%% GET DIRECTORY STRUCTURE
opts = SIN_TestSetup('Defaults', ''); 
wordspan_dir = fullfile(opts.general.root, 'playback', 'Word Span'); 

%% LISTS TO EDIT
list_dir = {'List_01', 'List_02', 'List_03', 'List_04'}; 

% Get the original files
for i=1:numel(list_dir)
    wavfiles{i}= regexpdir(fullfile(wordspan_dir, list_dir{i}), '[0-9]{2} Track', false);
end % 

% Concatenate file names
old_files = concatenate_lists(wavfiles); 

for i=1:numel(old_files)
    
    % Remove the track and stuff
    [PATHSTR,NAME,EXT] = fileparts(old_files{i}); 
    
    new_files{i} = fullfile(PATHSTR, [NAME(1:2) EXT]);     
    
    % Copy the old file to the new file location 
    copyfile(old_files{i}, new_files{i}); 
        
end % for i=1:numel(old_files)

if d.delete_old
    delete(old_files{:});
end % if d.delete_old