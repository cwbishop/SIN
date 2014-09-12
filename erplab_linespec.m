function [colorDef, styleDef]=erplab_linespec(NBIN)
%% DESCRIPTION:
%
%   Function to kick back default color and line style values similar to
%   ERPLAB. Not tested to see whether or not colors actually match
%   precisely, so take color with a grain of salt.
%
%   Code cannibalized from ploterps.m (part of ERPLAB).
%
% INPUT:
%
%
%
% OUTPUT:
%
%   

%linespec = {'blue' 'green' 'red' 'cyan' 'magenta' 'yellow' 'black'}; % color for plotting
defcolor = repmat({'k' 'r' 'b' 'g' 'c' 'm' 'y' },1, NBIN);% sorted according 1st erplab's version
defs     = {'-' '-.' '--' ':'};% sorted according 1st erplab's version
d = repmat(defs',1,length(defcolor));
defstyle = reshape(d',1,length(defcolor)*length(defs));
linespec = cellstr([char(defcolor') char(defstyle(1:length(defcolor))')])';

%
% COLOR & Style
%
colorDef = regexp(linespec,'\w*','match');
colorDef = [colorDef{:}];
styleDef = regexp(linespec,'\W*','match');
styleDef = [styleDef{:}];