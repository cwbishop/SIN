function [intel] = analysis_HASPI(x, y, varargin)
%% DESCRIPTION:
%
%   Wrapper for Jim Kates' intelligibility and quality
%   index. When written, CWB intended to call this from analysis_Hagerman,
%   which takes care of a lot of the logistical crap (like file matching,
%   temporal alignment, etc.). So this isn't a totally "stand alone"
%   function at the moment.
%
% INPUT:
%
%   x:
%
%   y:  
%
% Parameters:
%
%   'fsx':
%
%   'fsy':
%   
%   'calibration_rms':  RMS of calibration stimulus
%
%   'calibration_dBSPL':    SPL corresponding to calibration_rms. This is
%                           used to determine the actual output levels in
%                           SPL. This is used by the HASPI calculation, so
%                           important to get this right. 
%
% OUTPUT:
%
%   intel:  intelligibility index returned from HASPI_v1.m
%
%   quality:    quality index returned from HASQI_v2.m
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   2/15

%% GET INPUT PARAMETERS
d = varargin2struct(varargin{:});

