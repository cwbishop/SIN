function [all_tests, is_complete] = test_checklist(varargin)
%% DESCRIPTION:
%
%   This will verify all the tests that all tests that satify a given
%   regular expression have been completed successfully and results saved.
%   It will NOT ensure that the test executed properly, just that the test
%   was started and data saved in the appropriate folder.
%
%   The user will be presented with a warning for each test that does not
%   have any data saved.
%
% INPUT:
%
% Parameters:
%
%   subject_tests: cell array of subject tests. 
%
% Alternative to subject_tests:
%   
%   subject_id: string, subject ID
%
%   subject_directory:  string, directory in which subject data are stored.
%
% Must provide: 
%
%   test_regexp:    regular expression used to filter available tests
%                   listed in SIN_TestSetup.
%
% OUTPUT:
%
%   all_tests:  A list of all available tests that satisfy the regular
%               expression.
%
%   is_ complete:   Nx1 bool, where N is the number of elements in all_tests.
%               True if a test is complete, false if not complete. 
%
% Christopher W Bishop
%   University of Washington
%   4/15

%% MASSAGE KEY/VALUES INTO A STRUCTURE
opts = varargin2struct(varargin{:}); 

%% DEFAULTS
if ~isfield(opts, 'subject_tests') || ~iscell(opts.subject_tests), opts.subject_tests = {}; end 

% Populate List Regular Expression
if ~isfield(opts, 'test_regexp') || isempty(opts.test_regexp)
    
    % A list of likely regular expressions that the user may want to use
    regexp_list = {'MLST', 'HINT', 'ANL', 'Hagerman', 'Word Span'}; 
        
    [opts.test_regexp] = SIN_select(regexp_list, ...
        'title', 'Filter Selection', ...
        'prompt', 'Hold Ctrl to select multiple test types', ...
        'max_selections', 1); % Will eventually want to let the user select multiple filters for massive validation.
    
    % Covert test_regexp to a string
    opts.test_regexp = opts.test_regexp{1}; 
    
end % if ~isfield(opts, 'test_regexp') ...

% Populate subject selection
if (~isfield(opts, 'subject_id') || isempty(opts.subject_id)) && isempty(opts.subject_tests)
    
    % Get a full list of current subjects
    subject_list = SIN_getsubjects; 
    
    [opts.subject_id] = SIN_select(subject_list, ...
        'title', 'Select Subject', ...
        'prompt', 'Select the subject ID', ...
        'max_selections', 1); % Keep this fixed at 1 subject ID for validation, probably. 
    
    % Convert from cell to string
    opts.subject_id = opts.subject_id{1}; 
    
end % if ~isfield

%% GET ALL POSSIBLE TESTS
%   These are all the tests supported by SIN currently.
all_tests = SIN_TestSetup; 

%% TRANSLATE STRING TO regular expression
%   If the user happens to input a string that has special characters or
%   something in it, we need it to be regexp friendly. So, use
%   regexptranslate to do it.
opts.test_regexp = regexptranslate('escape', opts.test_regexp); 

% Filter the test list to only include those that satisfy the regular
% expression.
[~, mask] = regexp_cell(all_tests, opts.test_regexp);
all_tests = {all_tests{mask}}'; 

%% GET SUBJECT TESTS
%   These are the tests we have saved data for this particular subject.
%
%   User can provide a cell array of subject tests as well and we'll assume
%   this query has already been completed. 
if isempty(opts.subject_tests)
    opts.subject_tests = SIN_gettests('subjectID', opts.subject_id, ...
        'regexp', '.mat'); 
end % 

%% DISCARD PATH INFORMATION
for i=1:length(opts.subject_tests)
    [~, opts.subject_tests{i}, EXT] = fileparts(opts.subject_tests{i});
    opts.subject_tests{i} = [opts.subject_tests{i} EXT];    
end % for i=1:lebgth(sub...

%% SEARCH FOR DATA FOR ALL TESTS
%
%   Kick back a bool value for each test that indicates "Complete" (1) or
%   "incomplete" (0)
is_complete = false(length(all_tests),1); 
for i=1:length(all_tests)
    
    % Look for a match!
    [exp_index] = strfind(opts.subject_tests, all_tests{i});
%     display(all_tests{i});
    
    % Set the is_complete flag
    if ~isempty(cell2mat(exp_index))
        is_complete(i) = true;
    end % if any(exp_bool)
        
end % for i=1:length(all_tests)

% SUMMARY
%   Now we have a mask of complete for completed tests. We can now return
%   the test along with the mask for further display in some other fancy
%   dancy visualization approach. 
