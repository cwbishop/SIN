function varargout = SIN_calfiles(filename, varargin)
%% DESCRIPTION:
%
%   Function to return information about available calibration files. The
%   hope is to have it return a list of available calibration files or do
%   some basic checks on an existing calibration file (like making sure it
%   has the data its supposed to have in it ... whatever that might be).
%
% INPUT:
%
%   filename:   string, path to calibration file to validate (optional). If
%               left empty, returns a list of available calibration files.
%
%   XXX
%
% OUTPUT:
%
%   If empty:
%
%   calfiles:   cell array, a list of available calibration files
%
% Development:
%
%   1) Add regular expression input to filter files further (e.g., *.mat). 
% Christopher W. Bishop
%   University of Washington
%   5/14

%% INPUT CHECKS
if ~exist('filename', 'var'), filename=''; end 

% Return a list of calibration files
if isempty(filename)
    
    % Get calibration directory
    opts = SIN_TestSetup('Defaults'); 
    
    % Get calibration files 
    varargout{1} = ...
        regexpdir(opts.general.calibrationDir, opts.general.calibration_regexp, false);    
        
end % if isempty(filename)