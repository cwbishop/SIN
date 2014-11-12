function update_results
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
%   None
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

% Get a list of subjects
subjects = SIN_getsubjects; 

% For all subjects, update all tests
for i=1:numel(subjects)
    
    % Load subject specific tests
    tests = SIN_gettests('subjectID', subjects{i}, 'regexp', '.mat');
    
    % Loop through all tests, load them, then save them again
    for t=1:numel(tests)
        display(tests{t}); 
        
        results = SIN_load_results({tests{t}});
        
        results = results{1}; 
        
        SIN_saveResults(results, 'force_overwrite', true); 
        
    end % t 
    
end % for i=1:numel(subjects)