function [text_handle] = label_datapoint(x, y, varargin)
%% DESCRIPTION:
%
%   Adds a text label to a point in a figure. Does some basic checks to
%   make sure the text is generally visible, but uses some plausible
%   hard-coded values to do so. Might need to be more dynamic. 
%
% INPUT:
%
%   x:  one-element x coordinate of text label 
%
%   y:  one-element y coordinate of text label 
%
% Parameters:
%
%   'text':     text to use as label
%
%   'color':    text color
%
%   'fontsize': font size
%
%   'fontweight':   font weight
%
% Development:
%
%   1. Support addition of multiple text labels to the same figure
%
%   2. More intelligent handling of y-axis rescaling to make text visible. 
%      Rescaling will need to be based on text size instead of hard-coded. 
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET INPUT PARAMETERS
d = varargin2struct(varargin{:});

%% CREATE TEXT LABEL
text_handle = text(x, y, d.text, 'Color', color2colormap({d.color}), 'FontSize', d.fontsize, 'FontWeight', d.fontweight);

%% RESET Y-AXIS
% Make sure y-axis is set so we can see the text.
yrange = ylim; 
if yrange(1) > y, ylim([y - 2, yrange(2)]); end
yrange = ylim;
if yrange(2) < y, ylim([yrange(1), y + 2]); end 

%% RESET X-AXIS
xrange = xlim; 
if xrange(1) > x, xlim([x - 2, xrange(2)]); end
xrange = xlim;
if xrange(2) < x, xlim([xrange(1), x + 2]); end 