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
%   'scale_mode':   string specifying the scale mode. The scale mode
%                   determines if files are scaled by the sum of all
%                   previous scaling decisions (typically the case with the
%                   HINT or other 'byfile' adaptive_mode deliveries), or
%                   scales the sound by the most recent modification
%                   decision only. The latter is typically required to
%                   administer tests like the Acceptable Noise Level (ANL).
%
%                       'cumulative':   time series is scaled by the sum of
%                                       all previous adjustments (in
%                                       decibels). 
%
%                       'immediate':    the time series are scaled by the
%                                       most recent scaling parameter only.
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
%   2. Test with multiple element dB step. 
%
%   3. Need a smarter way to handle whether or not to plot data (xdata,
%   ydata). These are currently fields in the modcheck field ... might be
%   worth moving it to the modifier field ... makes more intuitive sense to
%   have it here. 
%
%   4. Need a smarter way to store xdata and ydata. Perhaps provide an
%   optional axis handle where the data can be written and stored for
%   plotting purposes. 
%       - Working with the figure handle will allow us to simplify and
%       isolate how data are passed between modifier and modcheck. 
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

%% GET GLOBAL VARIABLES
global trial;   % trial number set in portaudio_adaptiveplay
global modifier_num; % modification number. 

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
    d.player.modifier{modifier_num}.initialized=true;
    
    % Initialize plot data
    d.player.modifier{modifier_num}.xdata=trial;
    d.player.modifier{modifier_num}.ydata=0;

    Y=X; 
    return
end % if ~d.player.modifier{modifier_num}.initialized

%% GET APPROPRIATE STEP SIZE
dBstep=d.player.modifier{modifier_num}.dBstep(find(d.player.modifier{modifier_num}.change_step <= trial, 1, 'last'));

%% WHAT TO DO?
if ~isempty(mod_code)
    switch mod_code
        case {0, 1, -1}
            d.player.modifier{modifier_num}.history(end+1) = mod_code*dBstep;        
        otherwise
            error('Unknown modification code');
    end % switch
          
end % if ~isempty(mod_code)

%% SCALE TIME SERIES
channels=d.player.modifier{modifier_num}.channels; 

% Assign X to Y.
Y=X;

%% UPDATE MODIFIER HISTORY
d.sandbox.xdata=1:length(d.sandbox.xdata)+1; 

% Applies a cumulative change
%   So changes will be remembered and applied over different stimuli. 

% If there's any history at all.
%   Check necessary because if d.player.modifier is empty, sum(history) returns 0.
%   Not a big deal here, but better not to open ourselves to (unintended)
%   stimulus alterations. 
switch d.player.modifier{modifier_num}.scale_mode
    case {'cumulative'}
        
        % Scale by the sum of all dB steps
        sc=db2amp(sum(d.player.modifier{modifier_num}.history));
        
        % For plotting purposes
        d.sandbox.ydata(end+1)=sum(d.player.modifier{modifier_num}.history); 
        
    case {'immediate'}
        
        % Scale by the most recent dBstep
        sc=db2amp(d.player.modifier{modifier_num}.history(end));
        
        % For plotting
        d.sandbox.ydata(end+1)=d.player.modifier{modifier_num}.history(end);
        
    otherwise
        error('Unknown scale_mode');
end % switch

% Scale y-data
Y(:, channels)=Y(:, channels).*sc; 