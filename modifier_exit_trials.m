function [Y, d] = modifier_exit_trials(X, mod_code, varargin)
%% DESCRIPTION:
%
%   This will set the player state to exit based on the number of trials.
%   Several possible parameters available, including : trial minimum, trial
%   maximum.
%
% INPUT:
%
%   X:  time series
%
%   mod_code:   modification code (unused here)
%
% Paramters:
%
%   'trial_number': trial number (e.g., 20)
%
%   'trial_operator': string, comparison operator
%
%       '==', '>=', '<', etc.
%   
% OUTPUT:
%
%   Y:  unchanged time series - no modifications are done here
%
%   d:  updated options structure, potentially with changed player state
%
% Development:
%
%   1) Implement 'criterion_type' mode
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GET PARAMETERS
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
modifier_num=d.sandbox.modifier_num; 
trial = d.sandbox.trial; 

%% GET MODIFIER PARAMETERS
trial_number = d.player.modifier{modifier_num}.trial_number;
trial_operator = d.player.modifier{modifier_num}.trial_operator;

if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% ASSIGN RETURN DATA
%   This function does not alter the data directly, so just spit back the
%   original data
Y=X; 

%% IF THIS IS OUR FIRST CALL, JUST INITIALIZE 
%   - No modifications necessary, just return the data structures and
%   original time series.
if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

% Set flags based on criterion type
set_to_exit = false;

% Check criteria
if eval(['trial ' trial_operator ' ' num2str(trial_number)])
    set_to_exit = true;
end % if eval ...

% Set state to exit
if set_to_exit
    
    d.player.state = 'exit'; 
    
end % if set_to_exit