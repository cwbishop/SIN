function CMAP=color2colormap(CDEFS)
%% DESCRIPTION:
%
%   Simple lookup table to create a colormap from typical 'color' values
%   from plot, etc. (e.g., 'r', 'b', 'k', ...). This proved useful when
%   creating bar plots that follow the same color scheme as ERPLAB's
%   plotting functions.
%
%   Some of this code gleaned from 
%       http://www.mathworks.com/matlabcentral/fileexchange/1805-rgb-m/content/rgb.m
%   Which I found a link to on this discussion thread
%       http://stackoverflow.com/questions/5996437/how-to-convert-matlab-fixed-color-to-rgb-value
%
%   Also see discussion thread above for RGB values for short and long
%   color names.
%
% INPUT:
%
%   CDEFS:  cell array, each element is a string specifying one of MATLAB's
%           8 predefined colors.
%
% OUTPUT:
%
%   CMAP:   length(CMAPS) x 3 matrix with specified RGB color values.
%
% Christopher Bishop
%   University of Washington
%   1/14

% OUTPUTS
CMAP=[];

for i=1:length(CDEFS)
    
    % Switch for lookup table
    switch(CDEFS{i})
        case 'k', out=[0 0 0];
        case 'w', out=[1 1 1];
        case 'r', out=[1 0 0];
        case 'g', out=[0 1 0];
        case 'b', out=[0 0 1];
        case 'y', out=[1 1 0];
        case 'm', out=[1 0 1];
        case 'c', out=[0 1 1];
    otherwise
        warning(['Unrecognised colour "' in '", black assumed'])
        out=[0 0 0];	
    end % switch
    
    % Append color
    CMAP(i,:)=out; 
end % i=1:length(CDEFS