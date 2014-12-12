function your_table = load_lookup_table(varargin)
%% DESCRIPTION:
%
%   Load a lookup table and return a table structure. This is how CWB
%   should have written importHINT, but he didn't have the time to do it
%   properly. SO, now he gets to rewrite it and deal. 
%
% INPUT:
%
%   Parameters:
%
%       'path_to_table':    path to the lookup table. This can be relative
%                           or absolute, but CWB recommends absolute. 
%
%       'readtable_parameters': cell array, key/value pairs used with
%                               readtable function.
%
% OUTPUT:
%
%   your_table: your loaded table. 
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GATHER INPUT PARAMETERS
d = varargin2struct(varargin{:});

% Set some sensible defaults
if ~isfield(d, 'readtable_parameters'), d.readtable_parameters = {}; end 

% Load table 
your_table = readtable(d.path_to_table, d.readtable_parameters{:});