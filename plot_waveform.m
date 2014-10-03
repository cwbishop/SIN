function plot_waveform(DATA, FS, COL, WID, FHAND)
%% DESCRIPTION:
%
%   Simple function to plot a time varying waveform in MATLAB.
%
% INPUT:
%
%   DATA:   NxC matrix, where N is the number of samples and C is the
%           number of channels.
%   FS:     double, sampling rate. Typically an integer.
%   COL:    line color
%   WID:    line width
%   FHAND:  integer, figure to plot data in. Useful when plotting multiple
%           time waveforms on the same axis
%
% OUTPUT:
%
%   Figures and the like
%
% Christopher W. Bishop
%   University of Washington
%   2/14

%% INPUT AND DEFAULTS
if ~exist('COL', 'var') || isempty(COL), COL='b'; end
if ~exist('WID', 'var') || isempty(WID), WID=1; end 

% Select correct figure or create a new one
if ~exist('FHAND', 'var') || isempty(FHAND)
    figure, hold on;
else
    figure(FHAND);
    hold on;
end % if ~exist('FHAND', 'var') || isempty(FHAND)

%% TIME AXIS
x=0:1/FS:(length(DATA)-1)/FS;

%% PLOT DATA
plot(x, DATA, 'color', COL, 'linewidth', WID); 

%% MARKUP
xlabel('Time (s)');
ylabel('Amplitude'); 
