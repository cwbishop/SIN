function your_table = filter_table(your_table, varargin)
%% DESCRIPTION:
%
%   This function returns a filtered version of the original table that
%   satisfies all user-specified criteria. The criteria are essentially
%   fields and their corresponding acceptable values
%
%   Note: this is currently limited to a single value per field. 
%   
% INPUT:
%
%   your_table: a table structure returned from readtable or similar.
%
% Parameters:
%
%   Key/value pairs, where the key is the table field name and the value
%   are the acceptable values in the table.
%
%       E.g. 'track_name', '00' returns a table with only the entries whose
%       track names are '00'
%
% OUTPUT:
%
%   your_table: you guessed it, a filtered table structure
%
% Development:
%
%   1) Accept logic for "not" and all that jazz.
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GATHER INPUT PARAMETERS
d = varargin2struct(varargin{:});

% Construct a table mask
mask = false(size(your_table,1),1); 

% Get the filter names
filter_names = fieldnames(d);

% Get the filter
for i=1:numel(filter_names)
    
    mask(findcell(your_table.(filter_names{i}), d.(filter_names{i}))) = true;
    
end % for i=1:nume(filter_names)

% Apply the filter
your_table = your_table(mask,:); 