function [results] = SIN_load_results(filenames, varargin)
%% DESCRIPTION:
%
%   This function loads SIN results structures listed in file_names.
%
% INPUT:
%
%   filenames: cell array of file names pointing to results structures.
%
% Parameters:
%
%   None (yet)                       
%
% OUTPUT:
%
%   results:    a cell array, where each element is the results data loaded
%               from the corresponding cell of the file_name input
%
% Development:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   11/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% ERROR CHECKING
%   Need file names to have the same number 
if ~iscell(filenames) 
    filenames = {filenames};
end % 

%% INITIALIZE RETURN VARIABLE
results = cell(numel(filenames),1); 

%% LOOP THROUGH AND LOAD
for i=1:numel(filenames)
    
    % Load the results structure
    loaded_results = load(filenames{i}, 'results'); 
    
    % Assign to return variable
    results{i} = loaded_results.results; 
    
end % for i=1:numel(filenames)