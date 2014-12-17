function [Y, d] = modifier_instructions_by_trial(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Presents instructions using the "Instructions" GUI on a specific trial.
%   
% INPUT:
%
%   X:
%   
%   mod_code:
%
% Parameters:
%
%   'header':   string, header text for Instructions.fig. 
%
%   'body':     string, body text for Instructions.fig. This is basically
%               the instructions for the experimenter/listener.
%
%   'trial_number': which trial to present the instructions on. Note that 0
%                   presents the instructions prior to sound playback
%                   (i.e., prior to trial 1). 

%% GET KEY/VALUE PAIRS
d=varargin2struct(varargin{:}); 

%% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

% Assign return data
Y = X; 

% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% IF THIS IS OUR FIRST CALL, INITIALIZE, AND POTENTIALLY PRESENT INSTRUCTIONS
if ~d.player.modifier{modifier_num}.initialized
    
    % If the trial number is equal to 0, then present during initialization
    if d.player.modifier{modifier_num}.trial_number == 0
        
        % Call primary instructions interface
        Instructions(d.player.modifier{modifier_num});
            
    end % 
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized = true;
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

% If we are on the specified trial, then present instructions
if trial == d.player.modifier{modifier_num}.trial_number
    Instructions(d.player.modifier{modifier_num});
end % 