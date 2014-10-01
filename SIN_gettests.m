function [tests, dtimes] = SIN_gettests(varargin)
%% DESCRIPTION:
%
%   Function to return tests for a given subject.
%
% INPUT:
%
%   'subjectID':   string, subject identifier
%
%   Alternatively, can pass in SIN options structure. Opts must contain the
%   opts.subject.subjectID subfield. 
%
% OUTPUT:
%
%   tests:  cell array, list of tests
%
% Development:
%
%   1) Make compatible with command line inputs rather than options
%   structure.
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

%% GET TEST INFORMATION
tests = regexpdir(d.subject.subjectDir, '.mat', false);

%% GET RID OF "USEDLIST"
%   This will also return the "UsedList" since that's stored in the subject
%   directory, but this is not a test. So remove it. 
mask = true(numel(tests), 1); 
if ~isempty(tests)
    
    % Find and remove the "used lists"
    ind = findcell(tests, 'UsedList'); 
    
    if ~isempty(ind)
        mask(ind) = false;
    end % if ~isempty(ind)
    
end % if ~isempty(tests)

% Separate wheat from chaff. 
tests = {tests{mask}};

%% SORT TESTS BY DATE, WITH NEWEST FIRST

% Get test creation dates
dtimes = [];
for i=1:numel(tests)
    finfo = dir(tests{i});
    dtimes(i,1) = finfo.datenum;
end % for i=1:numel(tests)

% Sort test creation times
[dtimes, ind] = sort(dtimes, 'descend'); 

% Reorder tests
tests = {tests{ind}}'; 

%% CONVERT DATENUMS TO DATE STRING
dtimes = datestr(dtimes);