function [Y, d]=modifier_dBscale(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to adjust time series by decibels. Decibel step size(s) and
%   when to apply these step sizes must be specified by the user. 
%
% INPUTS:
%
%   X:  time series, where each column is a channel.
%   
%   mod_code:   integer, modification code. The modification code dictates
%               what change occurs (if any). These codes are modifier
%               specific, so read the help file carefully and pair the
%               modifier with an appropriate modification checker. This
%               modifier was originally written in conjunction with
%               HINT_modcheck_GUI.m.
%
%                   0:  no change
%                   -1: make sound quieter by dBstep
%                   1:  make sound louder by dBstep
%
% Parameters:
%
%   'dBstep':   double array, step sizes (in decibels). If multiple step
%               sizes will be used (i.e., the step size changes throughout
%               the test), 'change_step' must also be specified.
%
%   'change_step':  trial number at which to change begin using the
%                   corresponding element of dBstep. 
%
%       Example:    dBstep=[4 2]; change_step=[1 4]; With these settings,
%                   the algorithm will use a 4 dB step for trials 1-3, then
%                   a 2 dB step from trials 4 - N, where N is the number of
%                   total sentences (length(playback_list) above). 
%
%   'channels':     integer array, the channels to which the adaptive
%                   changes are applied. (optional). Defaults to
%                   d.playback_channels (specified in SIN_defaults or call
%                   to portaudio_adaptiveplay). 
%
% OUTPUT:
%
%   Y:  scaled time series
%
%   d:  structure, all kinds of parameters important for the modifier. 
%
% Development:
%
%   1. Complete additional scoring schemes (word_based, keyword_based). 
%
%   5. Change 'cumulative' mode so it just stores data in the 'history'
%   field differently and applies changes to the immediately preceding
%   sample. This will require addressing the issue mentioned in
%   portaudio_adaptiveplay (that is, always applying operations to the
%   original signal (X)) first. 
%
%   6. Should change flow so sounds are always scaled to the most recent
%   scaling factor, not matter the code. 
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

%% SET DEFAULTS
% Scale all channels by default
if ~isfield(d.player.modifier{modifier_num}, 'channels') || isempty(d.player.modifier{modifier_num}.channels), d.player.modifier{modifier_num}.channels=d.player.playback_channels; end 

%% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
if ~isfield(d.player.modifier{modifier_num}, 'history'), d.player.modifier{modifier_num}.history=[]; end 
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% IF THIS IS OUR FIRST CALL, JUST INITIALIZE 
%   - No modifications necessary, just return the data structures and
%   original time series.
if ~d.player.modifier{modifier_num}.initialized
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    % Initialize plot data
    d.sandbox.xdata=[];
    d.sandbox.ydata=[]; 

    % To be safe, assign input to output. 
    Y=X; 
    return
end % if ~d.player.modifier{modifier_num}.initialized

%% GET APPROPRIATE STEP SIZE
dBstep=d.player.modifier{modifier_num}.dBstep(find(d.player.modifier{modifier_num}.change_step <= trial, 1, 'last'));

channels=d.player.modifier{modifier_num}.channels; 

%% WHAT TO DO?
%   What do we do if no mod_code is provided?
if ~isempty(mod_code)
    switch mod_code
        case {0, 1, -1}
            
            % See how large of a step we need given user specifications
            dBstep = mod_code*dBstep; 

            %% SCALE TIME SERIES
            % Assign X to Y.
            Y=X;

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

            % Calculate scaling factor (amplitude)
            sc = db2amp(d.player.modifier{modifier_num}.history(end)); 

            % Apply scaling to signal
            Y(:, channels)=Y(:, channels).*sc; 

            % Update plotting information
            d.sandbox.xdata=1:length(d.sandbox.xdata)+1; % xdata (call #)
            d.sandbox.ydata(end+1)=d.player.modifier{modifier_num}.history(end);
            
        case {100}
            % This is the modification code (mod_code) sent by
            % ANL_modcheck_keypress when playback is "resumed" after a
            % pause. CWB noticed that the sounds are not scaled
            % appropriately when playback is resumed. This is meant to fix
            % that.
            
            % Copy over input data
            Y=X;
            
            % Grab the most recent scaling factor applied.
            sc = db2amp(d.player.modifier{modifier_num}.history(end)); 
            
            % Apply scaling factor to the appropriate channels.
            Y(:, channels)=Y(:, channels).*sc; 
            
        otherwise
            % We don't want to throw an error because sometimes other
            % mod_codes will be passed around that other modifiers know
            % what to do with. 
            %
            % Instead, just return the original data. There's nothing for
            % us to do here. 
            Y=X;
%             error('Unknown modification code');
    end % switch
          
end % if ~isempty(mod_code)