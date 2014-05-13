function [Y, d]=modifier_zerochannels(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to zero out specified channels.
%
% INPUT:
%
%   X:  
%   mod_code:   (ignored in this case, but allowed as input to conform to
%               modifier prototype)
%   
% Christopher W. Bishop
%   University of Washington
%   5/14

%% Globals
global modifier_num; 

%% MASSAGE INPUT ARGUMENTS
d=varargin2struct(varargin{:}); 

%% Zero channels
Y=X; 
Y(:, d.modifier{modifier_num}.channels)=0; 