function keyval = struct2keyval(opts)
%% DESCRIPTION:
%
%   Converts a structure into key/value inputs. This is essentially the
%   counter part to varargin2struct. 
%
%   Function is still a bit basic, but should be able to expand on this to
%   work with many data types.
%   
% INPUT:
%
%   opts:   a structure with arbitrary fields.
%
% OUTPUTS:
%
%   keyval: a cell array of key value pairs
%
% Christoher W Bishop
%   University of Washington
%   12/14

% Get the field names
key = fieldnames(opts);

% Now get field values
val = struct2cell(opts); 

% quick error check
if numel(key) ~= numel(val)
    error('mismatch key value');
end 

keyval = {};
for i=1:numel(key)
    keyval{1+ 2*(i-1)} = key{i}; 
    keyval{2 + 2*(i-1)} = val{i}; 
end % for i=1:numel(key)