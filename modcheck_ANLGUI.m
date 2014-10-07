function [mod_code, d]=modcheck_ANLGUI(varargin)
%% DESCRIPTION:
%
%   Modcheck function coupled with ANL_GUI. ANL_GUI is a simple "run",
%   "pause", "stop" GUI. This function returns codes compatible with
%   modifier_PlayControl based on toggled buttons
%
% INPUT
%
%   'instructions': Instruction text to read to listener
%
%   'title':    cell, figure title. 
%
% OUTPUT:
%
%   mod_code: Different key press outcomes return different codes (mod_code).
%
%       0:  no action is necessary. This arises if no toggle buttons were
%           clicked by the user
%
%       1:  The "Louder" toggle button was pressed
%
%       -1: The "Quieter" toggle button was pressed
%
%       99: The "Pause" button was pressed.
%
%       86: The "Complete Phase" button was clicked (86 from restaurant
%           biz)
%
%       100:    the "Begin/resume" button was clicked
%
% Development:
%
%   1. Must only allow volume changing if the player is in the "run" state.
%   If it's paused or stopped, don't change anything.    
%   
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% This modcheck is made to work with the SIN structure, which nests
% modchecks within the player substructure. If the function has been
% invoked directly (i.e., there is not 'player' field), then create a
% player field and stick the data in it. 
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% SET INITIALIZATION FIELD
%   The function is initialized by portaudio_adaptiveplayer. Need to track
%   whether or not this has been done yet. 
if ~isfield(d.player.modcheck, 'initialized') || isempty(d.player.modcheck.initialized), d.player.modcheck.initialized=false; end 

% Initialize modcheck
mod_code=[]; 

% If modcheck has not been initialized yet, then do so
if ~d.player.modcheck.initialized
    
    % Set initialization flag to true
    d.player.modcheck.initialized=true; 
    
    % Start ANL_GUI
    [~, handles]=ANL_GUI(d);
    
    % Set instructions
    set(handles.text_instructions, 'String', d.player.modcheck.instructions);
    
    % Save handles to modcheck function
    d.sandbox.ANLhandles=handles;
        
    % Set instructions
    set(handles.text_instructions, 'String', d.player.modcheck.instructions);
    
    % Assign null return for mod_code
    mod_code=[]; 

    % Set button state
    set(d.sandbox.ANLhandles.button_begin, 'Val', 0);
    set(d.sandbox.ANLhandles.button_pause, 'Val', 0); 
    set(d.sandbox.ANLhandles.button_complete, 'Val', 0); 
    set(d.sandbox.ANLhandles.button_increase, 'Val', 0); 
    set(d.sandbox.ANLhandles.button_decrease, 'Val', 0); 
    
    % Set figure Name (upper left corner)
    set(d.sandbox.ANLhandles.figure1, 'Name', d.player.modcheck.title); 
    
    % Return control
    return
end % if ~d.player.modcheck.initialized 

%% UPDATE FIGURE
drawnow; % Without this, the button values do not update. 

%% GET BUTTON INFORMATION
buttons=[get(d.sandbox.ANLhandles.button_begin, 'Val') get(d.sandbox.ANLhandles.button_pause, 'Val') get(d.sandbox.ANLhandles.button_complete, 'Val') get(d.sandbox.ANLhandles.button_increase, 'Val') get(d.sandbox.ANLhandles.button_decrease, 'Val')]; 

% If more than one toggle button has beeen pressed, throw a warning and
% reset buttons
if length(find(buttons~=0)) > 1
    
    % If multiple toggle buttons are pressed in the same refresh time
    % frame. Can happen when block duration is very long. 
    mod_code=0; 
    warning('Multiple buttons pressed. No action taken.');
    
elseif buttons(1) % run
    
    % Start/resume playback
    mod_code = 100;
    
elseif buttons(2)
    
    % Pause playback
    mod_code = 99; 
    
elseif buttons(3) % exit
    
    % Exit code
    %   Note that player state is set elsewhere through a modifier.
    mod_code = 86; 
    
elseif buttons(4)
    
    % Increase volume
    mod_code=1; 
    
elseif buttons(5)
    
    % Decrease volume
    mod_code=-1; 
    
else
    
    % No action needed
    mod_code=0; 
    
end % if find(buttons ...

% Reset toggle buttons
set(d.sandbox.ANLhandles.button_begin, 'Val', 0);
set(d.sandbox.ANLhandles.button_pause, 'Val', 0); 
set(d.sandbox.ANLhandles.button_complete, 'Val', 0); 
set(d.sandbox.ANLhandles.button_increase, 'Val', 0); 
set(d.sandbox.ANLhandles.button_decrease, 'Val', 0); 