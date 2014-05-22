function [Y, d]=modifier_pausePlayback(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function designed to "pause" playback. Playback is paused by fading
%   zeroing out sound and setting the player state to 'pause'. 
%
% INPUT:
%
%   X:  time series
%
%   mod_code:   modification code. Currently the code only responds if a
%               mod_code of 99 is received. All other codes have no effect.
%
% OUTPUT:
%
%   Y:  zeroed time series
%
%   d:  altered data structure with player state set to 'pause'. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
% trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

%% INITIALIZATION
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    % To be safe, assign input to output. 
    Y=X; 
    return
end % if ~d.player.modifier{modifier_num}.initialized

% Switch to change state of player
switch mod_code
    case {86}
        d.player.state='exit';
    case {99}
%         % pause code
%         Y = zeros(size(X)); 
        d.player.state='pause';
    case {100}
        d.player.state='run'; 
    otherwise
        % If we don't have anything to do, then just spit back the original
        % time series
        Y=X; 
end % switch

% State actions
switch d.player.state
    case {'pause' 'exit'}
        Y=zeros(size(X)); 
    otherwise
        Y=X;
end % switch