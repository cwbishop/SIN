function [Y, d]=modifier_dBscale_mixer(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function is designed to apply a decibel scaling factor to the invoking
%   player's mod_mixer. It's designed to be used with the
%   portaudio_adaptiveplay player. 
%
%   The function ultimately modifies the d.player.mod_mixer field. 
%
% INPUT:
%
%   X:
%
%   mod_code:
%
% Parameters: (these are typically set in SIN_TestSetup)
%
%   'data_channels':    integer array, the data channels (rows) of the
%                       mixer to which the scaling factor is applied.
%
%   'physical_channels':    integer array, the physical channels (columns)
%                           of the mixer to which the scaling factor is
%                           applied. 
%
%   'dBstep':   double array, step sizes (in decibels). If multiple step
%               sizes will be used (i.e., the step size changes throughout
%               the test), 'change_step' must also be specified.
%
%   'change_step':  trial number at which to change begin using the
%                   corresponding element of dBstep. 
%   
% OUTPUT:
%
%   Y:  unmodified time series. This function does *not* modify the time
%       series directly. Instead, it indirectly modifies the time series
%       through the mod_mixer.
%
%   d:  structure, all kinds of parameters important for the modifier. The
%       mod_mixer field is changed (scaling factor applied). 
%
% Development:
%
%   1. This will fail to work properly if the scaling value in the mixer
%   ever reaches 0, since dB(0) is -Inf. CWB not sure how to deal with this
%   at the moment. Maybe a special case? Dunno.
%
%   2. Modify change_step to accept function handles that define arbitrary
%   change information. This is more flexible than the current
%   instantiation, but not currently needed, so it's low on CWB's
%   to-do-list. 
%       - This will be important if we decide to use a NAL like algorithm
%       (see Keidser 2013 Journal of Audiology) 
% 
% Christopher W. Bishop
%   University of Washington
%   5/14

%% CONVERT INPUT PARAMETERS TO STRUCTURE
%   Useful when user provides both structures and parameter/value pairs as
%   inputs, as would likely be the case here. 
%
%   This doesn't work perfectly yet, but it's a good start. For instance,
%   it won't place parameter/value pairs in the modifier field. CWB can't
%   quite wrap his head around how to do that cleanly at the moment, so
%   leave it for now. 
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

%% GET MODIFIER PARAMETERS
data_channels = d.player.modifier{modifier_num}.data_channels; 
physical_channels = d.player.modifier{modifier_num}.physical_channels; 

%% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
if ~isfield(d.player.modifier{modifier_num}, 'history'), d.player.modifier{modifier_num}.history=[]; end 
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

%% INITIALIZE SCALING MATRIX
%   Initialize as dB(1) - no scaling applied. 
sc = db(ones(size(d.player.mod_mixer))); 

% Determine dBstep size
%   Added state check to make sure the player is running. If it isn't, then
%   we want to ignore any volume changes.
if ~isempty(mod_code) && isequal(d.player.state, 'run')
    
    %% GET APPROPRIATE STEP SIZE
    dBstep=d.player.modifier{modifier_num}.dBstep(find(d.player.modifier{modifier_num}.change_step <= trial, 1, 'last'));

    switch mod_code
        
        % These are codes that lead to scaling of the data when player is
        % in 'run' mode and has not been in the 'pause' state. 
        case {0, 1, -1}
            
            % See how large of a step we need given user specifications
            dBstep = mod_code*dBstep; 

            %% UPDATE MODIFIER HISTORY
            % Applies a cumulative change
            %   So changes will be remembered and applied over different stimuli. 

            % If there's any history at all.
            %
            %   Check necessary because if d.player.modifier is empty, sum(history) returns 0.
            %   Not a big deal here, but better not to open ourselves to (unintended)
            %   stimulus alterations. 
            if isempty(d.player.modifier{modifier_num}.history)
            %     sc = db2amp(dBstep);
                d.player.modifier{modifier_num}.history(end+1) = dBstep;
            else
            %     sc = db2amp(d.player.modifier{modifier_num}.history(end) + dBstep);
                d.player.modifier{modifier_num}.history(end+1) = d.player.modifier{modifier_num}.history(end) + dBstep;
            end % 
            
        otherwise
          
            dBstep=0; 
            
    end % switch
    
else
    
    % No change 
    dBstep = 0;            
    
end % if ~isempty(mod_code)

% Apply scaling factor to appropriate data/physical channels
sc(data_channels, physical_channels) = sc(data_channels, physical_channels) + dBstep; 

% Apply scaling factor to mod_mixer
d.player.mod_mixer = d.player.mod_mixer .* db2amp(sc);    