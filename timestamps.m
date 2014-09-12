function [stamps] = timestamps(N, FS, varargin)
%% DESCRIPTION:
%
%   Creates time stamps for a time series of length N. 
%
% INPUT:
%
%   N:  integer, number of samples in time series.
%
%   FS: double, assumed sampling rate.
%
% Parameters:
% 
%   'starttime':  double, the time to start at (in sec). (default = 0)
%
% OUTPUT:
%
%   stamps:    vector of length N. The time stamps for each sample.
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GATHER KEY/VALUE PAIRS
d=varargin2struct(varargin{:}); 

% Set defaults
if ~isfield(d, 'starttime') || isempty(d.starttime), d.starttime = 0; end 

% Time stamps
stamps = 0:1/FS:(N-1)/FS;

% Add user defined offset as start time.
stamps = stamps + d.starttime;