function [exp_index, exp_bool] = regexp_cell(entries, expression, varargin)
%% DESCRIPTION:
%
%   Applies regular expression to each element of a cell and returns the
%   indices into each cell that the regular expression can be found (if
%   it's there) an also a logical vector describing whether or not the
%   expression was found at all. The latter is helpful for masking data
%   (e.g., in update_results.m).
%
% INPUT:
%
%   entries:    cell array, each element must contain a string.
%
%   expression: regular expression.
%
% Parameters:
%
%   None (yet).
%
% OUTPUT:
%
%   exp_indices:
%
%   exp_bool:
%
% Christopher W Bishop
%   University of Washington
%   3/2015

%% GATHER PARAMETERS
opts = varargin2struct(varargin);

%% RETURN VARIABLES
exp_index = cell(length(entries),1);
exp_bool = false(length(entries),1); 

% Loop through each entry, see if we can find the expression
for i=1:numel(entries)
    
    exp_index{i,1} = regexp(entries{i}, expression);     
    
    % Did we find anything in this entry?
    if isempty(exp_index{i,1})
        exp_bool(i,1) = false;
    else
        exp_bool(i,1) = true;
    end % 
    
end % for i=1:numel(entries)