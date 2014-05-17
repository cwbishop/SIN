function [mod_code, d]=ANL_modcheck_keypress(varargin)
%% DESCRIPTION:
%
%   Modcheck function for use with portaudio_adaptiveplay.m. The function
%   opens a keyboard queue and monitors for specific key presses. If a
%   desired keypress is made, the function returns a modification code
%   (mod_code) that is subsequently passed on the listed 'modifier'.
%
%   Intended for use with ANL. 
%
% INPUT:
%
%   c:  structure, containing ... things ...
%
% OUTPUT:
%
%   XXX
%
%
% Development:
%
%   1. Having trouble with recognizing button presses since keyboard queue
%   is not released. 
%       - Should release the keyboard after the test session is over
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

% Initialize modcheck
mod_code=[]; 

% Keyboard check
%   Replace the try catch here with an "initialization" check, similar to
%   that used by HINT_modcheck_GUI.m 
warning('Need some love here'); 
try
    
    % First, try to check the queue.
    %   This will crash if the queue has not been created or started.
    [pressed, firstPress, ~, lastPress]=KbQueueCheck; 
    
    % Second, flush the queue to allow for independent responses
    KbQueueFlush;
    
catch 
    
    % If the queue has not been created or started, do so.
    KbQueueCreate([], d.player.modcheck.map); 
    
    % Now, start the queue to monitor for button presses
    KbQueueStart; 
    
    % Go ahead and check keyboard
    [pressed, firstPress, ~, lastPress]=KbQueueCheck; 
    
    % Flush the queue to allow for independent responses
    KbQueueFlush;
    
end % try/catch 

% Convert timestamps to key identifiers 
%   These are integer values that are easier to work with. 
firstPress=KbName(KbName(firstPress));
lastPress=KbName(KbName(lastPress)); 

%% INTERPRET KEY PRESSES
if ~pressed
    % If no keys were pressed, toss back a mod_code of 0. No modificaiton
    % necessary. 
    mod_code=0;
  
elseif numel(firstPress)>1 || firstPress ~= lastPress
    
    % If the user presses multiple buttons, don't do anything
    %   Note: CWB might want to change this action in the future. 
    warning('Multiple buttons pressed. No action taken.');
    mod_code=0;
    
elseif firstPress == d.player.modcheck.keys(1)
    
    % If the 'increase' button was pressed
    mod_code=1; 
    
elseif firstPress == d.player.modcheck.keys(2)
    
    % If the 'decrease' button was pressed, send a different code (-1). 
    mod_code=-1;     
    
end % if 