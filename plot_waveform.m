function plot_waveform(DATA, FS, COL, WID, FHAND, varargin)
%% DESCRIPTION:
%
%   Simple function to plot a time varying waveform in MATLAB.
%
% INPUT:
%
%   DATA:   NxC matrix, where N is the number of samples and C is the
%           number of channels.
%
%           Alternatively, DATA can be an N-element cell array. All
%           elements of the cell array are plotted on the same axes. Useful
%           for heads-up comparison between data traces.
%
%   FS:     double, sampling rate. Typically an integer.
%
%   COL:    line color
%
%   WID:    line width
%
%   FHAND:  integer, figure to plot data in. Useful when plotting multiple
%           time waveforms on the same axis
%
% Parameters:
%
%   'grid': bool, true (default, grid on), false (grid off)
%
% OUTPUT:
%
%   Figures and the like
%
% Christopher W. Bishop
%   University of Washington
%   2/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% INPUT AND DEFAULTS
if ~exist('COL', 'var') || isempty(COL), COL='b'; end
if ~exist('WID', 'var') || isempty(WID), WID=1; end 

if ~isfield(d, 'grid') || isempty(d.grid), d.grid = true; end

% Select correct figure or create a new one
if ~exist('FHAND', 'var') || isempty(FHAND)
    figure, hold on;
else
    figure(FHAND);
    hold on;
end % if ~exist('FHAND', 'var') || isempty(FHAND)

%% PLOT DATA
if iscell(DATA)
    
    hold on
    [colorDef, styleDef]=erplab_linespec(numel(DATA));
    
    for i=1:numel(DATA)
        
        y = DATA{i}; 
        x=0:1/FS:(length(y)-1)/FS;
        
        plot(x, y, 'color', colorDef{i}, 'LineStyle', styleDef{i}, 'linewidth', WID); 
    end % 
    
    
else
    x=0:1/FS:(length(DATA)-1)/FS;
    plot(x, DATA, 'color', COL, 'linewidth', WID); 
end % 

%% MARKUP

% Grid?
if d.grid
    grid on
end % if d.grid

xlabel('Time (s)');
ylabel('Amplitude'); 
