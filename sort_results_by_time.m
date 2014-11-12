function [test_times, chronological_order, preceding_filenames] = sort_results_by_time(filenames, varargin)
%% DESCRIPTION:
%
%   Sort SIN results structures by time. This function proved useful when
%   trying to find the most recent preceding file relative to a moment in
%   time. 
%
%   A specific example in which this was particularly useful was picking a
%   weight estimation results structure for analysis_Hagerman. Ideally,
%   users will use the most recent weight estimation for a particular
%   subject. 
%
%   This can be achieved by providing this function with a series of
%   results structures that can then be sorted. 
%
% INPUT:
%
%   'time_reference':   time (as returned by "now") used to order the
%                       preceding test results. (default = now)
%
% OUTPUT:
%
%   'chronological_order':  this returns the filenames in chronological
%                           order with the most recent results structure
%                           listed first.
%
%   'preceding_filenames':    this returns only the file names of the results
%                   structures that precede the time_reference. These are
%                   also in descending order (i.e., most recent listed
%                   first)
%
% Development:
%
%   None (yet) 
%
% Christopher W. Bishop
%   University of Washington
%   11/14


%% GET PARAMETERS
d=varargin2struct(varargin{:});

% default parameters
if ~isfield(d, 'time_reference') || isempty(d.time_reference), d.time_reference = now; end

%% % Get test creation dates
test_times = [];
for i=1:numel(filenames)
    
    % First, see if there's an end_time saved with the results. This will
    % be true for most if not all of our data moving forward as of 11/2014.
    % This will be a more reliable estimate of time when moving data across
    % machines since the file write time might be altered/lost when copying
    % files from one machine to the next. 
    %
    % If the variable cannot be found, then default to the file write time.    
    try 
        
        % This allows partial loading of just the end_time variable
        f = matfile(filenames{i});
        test_times(i,1) = f.end_time;
        
    catch
        
        % Sort based on the file write times. 
        %   This approach should generally be avoided in case files are
        %   transferred or copied without maintaining the file creation
        %   dates/times. 
        finfo = dir(filenames{i});
        test_times(i,1) = finfo.datenum;
    end % try catch
    
end % for i=1:numel(filenames)

%% SORT FOR CHRONOLOGICAL ORDER
[test_times, ind] = sort(test_times, 'descend'); 

% Reorder results filenames 
chronological_order =  {filenames{ind}}'; 

% List preceding filenames
preceding_filenames = {filenames{ test_times < d.time_reference}}';
