function [mod_code, d]=ANL_modcheck_keypress(varargin)
%% DESCRIPTION:
%
%   This modcheck is designed to be used in administering the Acceptable
%   Noise Level (ANL) test. It sets up and monitors a keyboard queue for
%   two possible button presses. The first button 
%
% INPUT:
%
%   'keys':     a two element integer array. The key numbers assigned to
%               the "increase" and "Decrease" keys, respectively. To obtain
%               the key number, use a command like : 
%                   [KbName('left') KbName('right')]
%
%               Note: CWB would discourage the use of the "up" and "down"
%               keys since they can lead to beeping at the MATLAB command
%               line. 
%
%   'map':      A 256x1 double array keyboard map. Keys to be monitored in
%               the keyboard queue (e.g., the 'increase' and 'decrease'
%               button described in the keys field above) must be set to 1.
%               Keys to ignore must be set to 0. Here's an example using
%               the 'left' and 'right' key described above. 
%                   opts.player.modcheck=struct(...
%                       'fhandle',  @ANL_modcheck_keypress, ...     % check for specific key presses
%                       'keys',     [KbName('left') KbName('right')], ...  % first key makes sounds louder, second makes sounds quieter
%                       'map',      zeros(256,1));
%         
%                   % Assign keys in map
%                   opts.player.modcheck.map(opts.player.modcheck.keys)=1;
%
% OUTPUT:
%
%   mod_code: Different key press outcomes return different codes (mod_code).
%       0:  no action is necessary. This arises if no keys were pressed or
%           if multiple keys were pressed, or some other bizarre
%           combination of keys were pressed (like two keys since the last
%           check). 
%       1:  The "increase" button was pressed. The sound should be made
%           quieter by some set amount. Step size determined by the
%           modifier settings.
%       -1:  The "decrease" button was pressed.
%
%
% Development:
%
%   1. Need to release keyboard queue at end of test. Not sure how to do
%   this cleanly since there is only one "trial" for the ANL. 
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
    
    % Release the keyboard queue (in case something else has its attention)
    %   This could lead to weird and difficult to debug errors, a warning
    %   might be smarter. 
    KbQueueRelease;
    
    % Create the keyboard queue
    KbQueueCreate([], d.player.modcheck.map); 
    
    % Start the keyboard monitor
    KbQueueStart; 
    
    % Assign null return for mod_code
    mod_code=[]; 
    
    % Return control
    return
end % if ~d.player.modcheck.initialized 

% On subsequent calls, the queue has already been initialized. So we check
% the queue and determine if any action is necessary.
[pressed, firstPress, ~, lastPress]=KbQueueCheck; 

% Flush the queue
%   Removes all keypresses from the queue. 
KbQueueFlush; 
  
% Convert timestamps to key identifiers 
%   These are integer values that are easier to work with. 
firstPress=KbName(KbName(firstPress));
lastPress=KbName(KbName(lastPress)); 

%% INTERPRET KEY PRESSES
%   Different key press outcomes return different codes (mod_code).
%       0:  no action is necessary. This arises if no keys were pressed or
%           if multiple keys were pressed, or some other bizarre
%           combination of keys were pressed (like two keys since the last
%           check). 
%       1:  The "increase" button was pressed. The sound should be made
%           quieter by some set amount. Step size determined by the
%           modifier settings.
%       -1:  The "decrease" button was pressed.
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

%% RELEASE KEYBOARD QUEUE AFTER LAST TRIAL
%   Only release keyboard queue after the last trial is complete and the
%   last stimulus block has been presented. 
%
%   Check only complete if there's a 'sandbox' field present. CWB thinks
%   this will help make the function more "Stand alone", but his
%   subconscious says he's full of it ...
if isfield(d, 'sandbox') && d.sandbox.trial == numel(d.sandbox.playback_list) && d.sandbox.block_num == d.sandbox.nblocks
    KbQueueStop;
    KbQueueRelease;
end % 
