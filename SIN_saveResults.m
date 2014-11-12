function SIN_saveResults(results, varargin)
%% DESCRIPTION:
%
%   Basic function to save results. This was originally written to save
%   results from portaudio_adaptiveplay, but shouldn't be difficult to
%   expand to various results formats.
%
% INPUT:
%
%   results:    portaudio_adaptiveplay results structure. This may be a
%               multielement structure gathered by SIN_runTest as well. If
%               this is the case, then the multi-part results structure
%               will be saved to the specific.saveData2mat field specified
%               in the first element's results structure. 
%
%               Note: saving multipart data in the same file made
%               determining the order of multipart tests more robustly and
%               to keep the parts grouped together a more convenient way. 
%
% Parameters:
%
%   'force_overwrite':  bool, if set to true, then forces an overwrite. If
%                       false then prompts user for information (default =
%                       false)
%
% OUTPUT:
%
%   Saved mat file
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% Set defaults
if ~isfield(d, 'force_overwrite') || isempty(d.force_overwrite), d.force_overwrite = false; end

%% GET RUNTIME OPTIONS
%   - This will return the most "up-to-date" information. It's possible
%   that the player (or a modifier attached to the player) will change a
%   relevant field. So we want to work with that rather than the
%   UserOptions.
%
%   - Only grab options structure from first element of results and save
%   the whole structure to a single file. 
opts = results(1).RunTime; 

%% FILE NAME
%
%   - The file name is a combination of the subject ID, test ID, and the
%   UUID. This generates what CWB hopes is a unique and informative file
%   name that will make it easy for users to collect data for analysis
%   purposes later.
%
%   Results will be placed in the appropriate test folder within
%   subject_data (or wherever data are stored). 
% fname = fullfile(opts.subject.subjectDir, opts.specific.testID, [opts.subject.subjectID '-' opts.specific.testID '-' opts.specific.uuid]);
fname = opts.specific.saveData2mat; 

% Check to see if the file exists. If it does, ask the user if he wants to
% overwrite it. If yes, proceed. If not, then return control without
% writing file. 
if (logical(exist(fname, 'file')) || logical(exist([fname '.mat'], 'file'))) && ~d.force_overwrite
    
    response = '';
    while ~isequal(response, 'y') && ~isequal(response, 'n')
        response = lower(input(['File "' fname '" exists. Overwrite? (y/n)'], 's'));
    end % while
    
    % If we don't want to overwrite the file, then append the date to the
    % file name and write it.
    %   This chunk of code is not well-tested since the UUIDs make it
    %   nearly impossible for two files to be exactly the same. 
    if isequal(response, 'n')
        fname = [fname '-1'];
        results(1).RunTime.specific.saveData2mat = fname; 
        SIN_saveResults(results); 
    end %
    
end % if logical(exist(fname ...
    
%% SAVE RESULTS
%
%   We need to save files as version 7.3 to allow partial loading. Partial
%   loading may speed things up considerably, particularly in functions
%   like SIN_gettests which sorts based on data stored in the results
%   struture itself. 
%
%   CWB cannot figure out a way to grab a subfield of a structure, so we
%   need to save the most likely informative (and small) fields as
%   independent variables in the mat file. This approach has worked
%   resonably well for CWB thus far.
%
%   Note: if the saved information is changed, try running update_results.m
%   to modify the saved data. 
start_time = results(end).RunTime.sandbox.start_time; 
end_time = results(end).RunTime.sandbox.end_time; 
save(fname, 'start_time', 'end_time', 'results', '-v7.3');