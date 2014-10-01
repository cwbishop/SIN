function [Y, d]=modifier_ShowInstructions(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Wrapper to present basic instructions during player startup. Designed
%   to be paired with Instructions.fig.
%
%   This specific "modifier" is a bit of a misnomer. It doesn't actually
%   modify anything. It just presents instructions at the beginning of each
%   test.
%
% INPUT:
%
%   X:  audio stream data.
%
%   mod_code:   modification code (ignored)
%
% Parameters:
%
%   'header':   string, header text for Instructions.fig. 
%
%   'body':     string, body text for Instructions.fig. This is basically
%               the instructions for the experimenter/listener.
%
% OUTPUT:
%
%   Y:  modified audio stream (not modified here).
%
%   d:  modified options structure (not modified here).
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET PARAMETERS
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

modifier_num=d.sandbox.modifier_num; 

% Set initialized flag to 0
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% ASSIGN RETURN DATA
%   This function does not alter the data directly, so just spit back the
%   original data
Y=X; 

%% IF THIS IS OUR FIRST CALL, INITIALIZE AND PRESENT INSTRUCTIONS
%   - No modifications necessary, just return the data structures and
%   original time series.
if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized = true;
    
    % Call instructions GUI
    Instructions(d.player.modifier{modifier_num}); 
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized
