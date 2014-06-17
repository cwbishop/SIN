function [Y, d] = modifier_NALscale_mixer(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to query and apply the appropriate decibel (dB) scaling factor
%   from the (currently running) algo_NALadaptive function to the
%   appropriate elements of the player's mod_mixer. 
%
% INPUT:
%
%   X:  data to scale (potentially)
%
%   mod_code:   modification code. This is *ignored* by this function.
%
%   Parameters include the following: These are similar to
%   modifier_dBscale.m
%
%   'data_channels':    integer array, the data channels (rows) of the
%                       mixer to which the scaling factor is applied.
%
%   'physical_channels':    integer array, the physical channels (columns)
%                           of the mixer to which the scaling factor is
%                           applied. 
%
% OUTPUT:
%
%   Y:  (potentially) scaled data
%
%   d:  updated options structure
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% PLACE PARAMETERS IN STRUCTURE
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if


%% ASSIGN RETURN DATA
%   This function does not alter the data directly, so just spit back the
%   original data
Y=X; 

%% GET IMPORTANT VARIABLES FROM SANDBOX
trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

%% GET MODIFIER PARAMETERS
data_channels = d.player.modifier{modifier_num}.data_channels; 
physical_channels = d.player.modifier{modifier_num}.physical_channels; 

%% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
% if ~isfield(d.player.modifier{modifier_num}, 'history'), d.player.modifier{modifier_num}.history=[]; end 
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% IF THIS IS OUR FIRST CALL, JUST INITIALIZE 
%   - No modifications necessary, just return the data structures and
%   original time series.
if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

%% INITIALIZE SCALING MATRIX
%   Initialize as dB(1) - no scaling applied. 
sc = db(ones(size(d.player.mod_mixer))); 

%% GET NAL INFORMATION FROM SANDBOX
%   The NAL structure is assigned to the sandbox by modcheck_HINT_GUI
NAL = d.sandbox.NAL; 

% Get the dBstep from the data structure
if ~isempty(NAL.dBstep)
    dBstep = NAL.dBstep(end); 
else
    warning('This is sloppy'); 
    dBstep = 0; % no scaling if there's nothing in dBstep. 
end % dBstep

% Apply scaling factor to appropriate data/physical channels
sc(data_channels, physical_channels) = sc(data_channels, physical_channels) + dBstep; 

% Apply scaling factor to mod_mixer
d.player.mod_mixer = d.player.mod_mixer .* db2amp(sc);   