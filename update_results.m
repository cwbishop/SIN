function update_results(subjects, varargin)
%% DESCRIPTION:
%
%   Function loads all results for all subjects and rewrites them by
%   calling SIN_saveResults. This in effect updates the saved results
%   structures to match whatever the current format is.
%
%   This has proved useful when adding additional variables to save to the
%   results structure (e.g., end_time). 
%
% INPUT:
%
%   subjectID:  cell array of subject IDs to update. (default =
%               SIN_getsubjects)
%
% Parameters:
%
%   'test_regexp':  A regular expression used to filter the tests that
%                   will be updated. To update all tests, set to '.*'.
%                   Other regular expressions must be experimented with.
%                   See matlab documentation and the web for more
%                   information.
%
%   'update_analysis':  bool, if true, then the analysis field is updated.
%
% OUTPUT:
%
%   Saved results structures
%
% Development:
%
%   1) Allow updating of a subset of subjects/results structures
%
% Christopher W. Bishop
%   University of Washington
%   11/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% Get a list of subjects
if ~exist('subjects', 'var')
    subjects = SIN_getsubjects; 
end % if ~exist ...

% For all subjects, update all tests
for i=1:numel(subjects)
    
    % Load subject specific tests
    tests = SIN_gettests('subjectID', subjects{i}, 'regexp', '.mat');
    
    % Apply regular expression and mask to tests
    [~, test_mask] = regexp_cell(tests, d.test_regexp); 
    tests = {tests{test_mask}}'; 
    
    % Loop through all tests, load them, then save them again
    for t=1:numel(tests)
        display(tests{t}); 
        
        results = SIN_load_results({tests{t}});
        
        results = results{1}; 
        
        %% MODIFY SPECIFIC SUBFIELDS
        try 
            opts = SIN_TestSetup(results(1).UserOptions.specific.testID, subjects{i});
        
            % Error check to make sure the test structure hasn't changed
            % dramatically.
            if length(opts) ~= length(results)
                error('Test has changed structure dramatically. Might require more fiddling')
            end % 

            % Analysis
            if d.update_analysis

                for a=1:length(results)

                    results(a).RunTime.analysis = opts(a).analysis; 

                end % for i=1:length(results)

            end % 
        catch
            
            %% THIS WOULD BE A GOOD PLACE TO HANDLE MATCHING CASES. 
            %   This will likely need to be an unwieldy switch statement. 
            %   But this might be necessary for reverse compatibility
            %   reasons.
            warning(['Could not update ' results(1).RunTime.specific.testID '. Likely that the test name has changed.']); 
            
        end % try/catch
                
        SIN_saveResults(results, 'force_overwrite', true); 
        
    end % t 
    
end % for i=1:numel(subjects)