function [Y, d]=modifier_trackMixer(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to track mod_mixer settings. This is done by appending the
%   current state of the mod_mixer to a variable established in d.sandbox.
%
% INPUT:
%
%   X:
%
%   mod_code:   Ignored by this function. 
%
% OUTPUT:
%
%   Y:  unaltered
%
%   d:  options structure with most recent state of mod_mixer appended to
%       d.sandbox.mod_mixer
%
% Development:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% CONVERT INPUT PARAMETERS TO STRUCTURE
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

% Assign output data
Y=X; 

% Get modifier_num
modifier_num=d.sandbox.modifier_num; 

% Set initialization to false by default
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% INITIALIZATION
%   - 
if ~d.player.modifier{modifier_num}.initialized
    
    % Set initialization
    d.player.modifier{modifier_num}.initialized=true; 
    
    % Create empty sandbox variable
    d.sandbox.mod_mixer=[]; 

    return;
    
end % if ~d.player.mod ...

% Append mod_mixer to matrix
%   For first iteration, end+1 throws a shoe (adds to dim3 = 2). 
if isempty(d.sandbox.mod_mixer)
    d.sandbox.mod_mixer(:,:,1) = d.player.mod_mixer; 
else
    d.sandbox.mod_mixer(:,:,end+1) = d.player.mod_mixer;
end % 