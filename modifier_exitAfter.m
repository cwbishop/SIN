function [Y, d]=modifier_exitAfter(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function that sets player status to "exit" after an arbitrary
%   expression evaluates to "true". This is designed to work with
%   "player_main.m"
%
% INPUT:
%
%   X:  time series. This is not altered in this modifier
%
%   mod_code:   modification code from whatever modcheck is run.
%
% Fields:   These fields must be populated in the corresponding modifier
%           field
%
%   'expression':   string, expression to evaluate. Must evaluate to true
%                   or false. If TRUE, the modifier sets player status to
%                   exit.
%
% OUTPUT:
%
%   Y:  unaltered data series
%
%   d:  modified options structure from player. 
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET OPTIONS STRUCTURE
d=varargin2struct(varargin{:}); 

modifier_num=d.sandbox.modifier_num; 

% Assign return Y variable. We aren't modifying this
Y = X; 

% Has modifier been initialized?
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

%% GET MODIFIER NUMBER
% mod_num = d.sandbox.mod_num;

%% EVALUATE EXPRESSION
if eval(d.player.modifier{modifier_num}.expression)
    d.player.state = 'exit';
end % if eval ...