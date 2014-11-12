function [all_tests, test_times] = SIN_gettests(varargin)
%% DESCRIPTION:
%
%   Function to return tests for a given subject.
%
% INPUT:
%
%   'subjectID':   string, subject identifier
%
%   'regexp':   a regular expression used to filter the tests. This may
%               prove useful when the user wants all the lists of a
%               specific species. (default = '.mat'); 
%
%   'time_reference':   see sort_results_by_time for more information. 
%
%   Alternatively, can pass in SIN options structure. Opts must contain the
%   opts.subject.subjectID subfield. 
%
% OUTPUT:
%
%   tests:  cell array, list of tests temporally sorted by the file date
%           time. This may pose some problems when copying data to
%           different systems. 
%
%   test_times: time of each test used for sorting purposes. For more
%               details, see sort_results_by_time.m
%
% Development:
%
%   1) Make compatible with command line inputs rather than options
%   structure.
%
%   2) Add option to sort based on results structure write time. Not sure
%   how best to go about this yet, but we'll need this sorting option when
%   copying data to different machines. The file creation time will not
%   necessarily be preserved and we want the files to load the same on
%   different machines. 
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

%% IS THIS AN OPTIONS STRUCTURE
%   If not, then force it to look like one.
if ~isfield(d, 'subject')
    d = SIN_TestSetup('Defaults', d.subjectID); 
end % isstruct

% Set defaults
if ~isfield(d, 'regexp'), d.regexp = '.mat'; end

%% GET TEST INFORMATION
all_tests = regexpdir(d.subject.subjectDir, d.regexp, false);

%% GET RID OF "USEDLIST"
%   This will also return the "UsedList" since that's stored in the subject
%   directory, but this is not a test. So remove it. 
mask = true(numel(all_tests), 1); 
if ~isempty(all_tests)
    
    % Find and remove the "used lists"
    ind = findcell(all_tests, 'UsedList'); 
    
    if ~isempty(ind)
        mask(ind) = false;
    end % if ~isempty(ind)
    
end % if ~isempty(tests)

% Separate wheat from chaff. 
all_tests = {all_tests{mask}};

%% SORT TESTS BY DATE, WITH NEWEST FIRST
%   This functionality was modularized since CWB needed it elsewhere as
%   well. 
[test_times, all_tests] = sort_results_by_time(all_tests); 

%% CONVERT DATENUMS TO DATE STRING
test_times = datestr(test_times);