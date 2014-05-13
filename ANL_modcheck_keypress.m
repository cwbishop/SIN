function [mod_code, d]=ANL_modcheck_keypress(varargin)
%% DESCRIPTION:
%
%   Modcheck function for use with portaudio_adaptiveplay.m. The function
%   opens a keyboard queue and monitors for specific key presses. If a
%   desired keypress is made, the function returns a modification code
%   (mod_code) that is subsequently passed on the listed 'modifier'.
%
% INPUT:
%
%   c:  structure, containing ... things ...
%
% OUTPUT:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

%% DETERMINE PARAMETERS
%   If an input structure is provided, then we don't need to run
%   SIN_defaults.
%
%   If an input strucutre is not provided, then we need to run SIN_defaults
%   to figure out which way is up. 
try p.modcheck.keys;
    d=p; 
    clear p;
catch
    defs=SIN_defaults;
    d=defs.anl;
end % 

% Keyboard check
try
    
    % First, try to check the queue.
    %   This will crash if the queue has not been created or started.
    [pressed, firstPress, ~, lastPress]=KbQueueCheck; 
    
    % Second, flush the queue to allow for independent responses
    KbQueueFlush;
    
catch 
    
    % If the queue has not been created or started, do so.
    KbQueueCreate([], d.modcheck.map); 
    
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
    needmod=false; 
    mod_code=0;
  
elseif numel(firstPress)>1 || firstPress ~= lastPress
    
    % If the user presses multiple buttons, don't do anything
    %   Note: CWB might want to change this action in the future. 
    warning('Multiple buttons pressed. No action taken.');
    needmod=false; 
    mod_code=0;
    
elseif firstPress == d.modcheck.keys(1)
    
    % If the 'increase' button was pressed
    needmod=true;
    mod_code=1; 
    
elseif firstPress == d.modcheck.keys(2)
    
    % If the 'decrease' button was pressed, send a different code (-1). 
    needmod=true;
    mod_code=-1;     
    
end % if 