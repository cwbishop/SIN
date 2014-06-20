function opts = SIN_assignUUID(opts, varargin)
%% DESCRIPTION:
%
%   SIN uses a Universally Unique IDentifier (UUID) to track individual
%   tests and test sequences. This function assigns UUIDs in a
%   semi-intelligent way by ensuring that individual tests receive a UUID
%   and all tests within a test sequence share a common UUID. This should
%   allow the user some unimbiguous information to quickly pool results.
%
%   Uses uuidgen.m to generate the UUID. uuidgen can be downloaded here:
%       http://www.mathworks.com/matlabcentral/fileexchange/21709-uuid-generation/content/uuidgen.m
%
% INPUT:
%
%   opts:   SIN options structure
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   opts:   options structure with UUID added to the "specific" field of
%           each test.
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

% All elements of opts receive the same UUID
uuid = uuidgen; 

for i=1:numel(opts)
    
    opts(i).specific.uuid = uuid;
    
end % for i=1:numel ...