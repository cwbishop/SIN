function [rms_out, aw_timeseries] =aw_rms(timeseries,fs,plotFlag)
%% DESCRIPTION:
%
%   Estimates A-weighted RMS of a time series. Filter coefficients are
%   generated in the filterA function. 
%
% INPUT:
%
%   timeseries: the time series to filter. 
%
%   fs: sampling rate of time series
%
%   plotFlag:   if set, plots the A-weighted filter (from filterA).
%
% OUTPUT:
%
%   rms_out:    the A-weighted rms estimates
%
%   aw_timeseries:  the A-weighted time series.
%
% Development:
%
%   None (yet)
%
% Original Author Unknown, but probably Kevin Hill or Jess Kerlin
%   Modified by Christopher W Bishop
%   University of Washington
%   10/14

if ~exist('plotFlag','var') || isempty(plotFlag)
    plotFlag = 0;
end

f=0:10:fs/2;
n=200;
a=filterA(f,plotFlag);

%normalize frequency to Nyquist 
f=2*f/fs;

Hdw=design(fdesign.arbmag(n,f,a));

aw_timeseries=fftfilt(Hdw.Numerator,timeseries);

rms_out=rms(aw_timeseries);
