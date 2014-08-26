function player_WMP(X, varargin)
%% DESCRIPTION:
%
%   Player that uses Windows Media Player for sound/video playback. This
%   requires a valid ActiveX controller to be installed. 
%
%   This player has some overlapping functionality with player_PTB, but
%   goes about it differently and has the added support of presenting
%   audiovisual files (e.g., MP4s). PTB can theoretically do this, but CWB
%   ran into countless errors and issues with GStreamer that led to
%   constant system crashes on Windows 7 running MATLAB 2013b and PTB-3.
%   Ultimately, the issues were crippling and CWB had to seek out other
%   options. 
%
%   The ActiveX commands were inspired by 
%
%   http://www.mathworks.com/matlabcentral/fileexchange/4441-activex-control-for-windows-media-player
%   
%   Unfortunately, this player did not work on CWB's build, but the
%   individual commands still worked fine. 
%
%   A scoring interface can be plugged into this as well, similar to the
%   MOD CHECK GUIs used in player_PTB. Importantly, however, there's *no*
%   adaptive capabilities in this player. This is meant simply for
%   sound/video playback and, potentially, some basic sound recording
%   (pending). 
%
%   In CWB's specific case, he installed and used 
%       http://sourceforge.net/projects/asiowmpplg/
%   to force Windows Media Player to use the ASIO playback drivers. 
%   
%   A detailed list of properties/methods of the ActiveX class can be found
%   http://msdn.microsoft.com/en-us/library/windows/desktop/dd563945(v=vs.85).aspx
%   
%
% INPUT:
%
%   X:  cell array of file names to play. This can, theoretically, be any
%       file format supported by WMP. If the file type is not supported,
%       CWB suggests adding the appropriate codec to sound playback.
%
% Parameters:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   08/2014

%% PARAMETERS
d=varargin2struct(varargin{:}); 

%% SET BASIC VARIABLES
% Create additional fields in 'sandbox'
%   Dummy values assigned as placeholders for intialization purposes. 
d.sandbox.trial=-1; % trial number
d.sandbox.nblocks=-1; % nblocks, the block number within the trial 
d.sandbox.block_num=-1; % block number we are in. 
d.sandbox.modifier_num=[];
d.sandbox.modcheck_num=1; % hard-coded for now since code only allows a single modcheck/trial (for now)
d.sandbox.playback_list=X;
%% GET SCREEN INFORMATION

% Initialize modcheck
[mod_code, d]=d.player.modcheck.fhandle(d);

%% OPEN ACTIVE X CONTROL
wmp = actxcontrol('WMPlayer.OCX.7', [0 0 960 540], gcf);

% wmp.settings.autoStart = false; 

%% LOOP THROUGH FILES AND PLAY THEM
for trial=1:numel(X)
    
    % Update variables
    d.sandbox.trial = trial; 
    
    % Set the current file
    wmp.URL = X{trial};
    
    % Info on playstates here
    % http://msdn.microsoft.com/en-us/library/windows/desktop/dd564085(v=vs.85).aspx
%     display(wmp.playState); 
    
    % Wait for playback to start 
    while isempty(strfind(wmp.playState, 'Playing')), display(wmp.playState); end     
    
    % Sit until playback has finished
    while isempty(strfind(wmp.playState, 'Stopped')), display(wmp.playState); end     
    
end % for i