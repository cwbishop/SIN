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

% Get playback/recording device information
try
    % Get playback device information 
    [pstruct]=portaudio_GetDevice(d.player.playback.device);    % playback device structure
    [rstruct]=portaudio_GetDevice(d.player.record.device);      % recording device structure
catch
    InitializePsychSound; 
    [pstruct]=portaudio_GetDevice(d.player.playback.device);
    [rstruct]=portaudio_GetDevice(d.player.record.device); 
end % try/catch
% Set FS
FS = d.player.playback.fs;

% Load noise 
[noise, fs] = audioread('C:\Users\cwbishop\Documents\GitHub\SIN\playback\Noise\ISTS-V1.0_60s_24bit.wav'); 

% Resample to sampling rate
noise = resample(noise, FS, fs);

% Set buffer size
buffer_nsamps = size(noise,1); 

% Initialize PTB sound playback using ASIO drivers.
if (d.player.record_mic && isempty(comp_struct(d.player.playback.device, d.player.record.device, 0))) 
        
    % Load in duplex mode (mode 3) if the recording and playback
    % devices are the same device. 
    phand = PsychPortAudio('Open', pstruct.DeviceIndex, 3, 0, FS, [pstruct.NrOutputChannels rstruct.NrInputChannels], d.player.playback.internal_buffer);

    % Now the recording handle is the same as the playback handle. 
    rhand = phand;

    % Allocate Recording Buffer
    PsychPortAudio('GetAudioData', rhand, d.player.record.buffer_dur); 

    % We're in duplex mode, so set the flag 
    isDuplex = true;
else

    % If we don't need duplex mode, just open the device. 
    phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels, d.player.playback.internal_buffer);
end % if (d ...

% Add noise to noise specific channels
%   - Use the mod_mixer settings to do this.
noise = noise * d.player.mod_mixer; 

% Fill the playback buffer
PsychPortAudio('FillBuffer', phand, noise');

%% INITIALIZE MODCHECK and MODIFIER
%   These functions often have substantial overhead on their first call, so
%   they need to be primed (e.g., if a figure must be generated or a sound
%   device initialized).

% Call modcheck
%   this is not really a 'modcheck' here, but we'll use the same code.
[mod_code, d]=d.player.modcheck.fhandle(d);

% Start noise playback
%   This will loop until we stop it below. Infinite loop, so continuous
%   masker presented. 
PsychPortAudio('Start', phand, 0, [], 0);

%% OPEN ACTIVE X CONTROL
%   Use Screen('Resolution', window number) to get screen resolution and
%   configure player size
wmp = actxcontrol('WMPlayer.OCX.7', [0 0 1920 1200], gcf);

% Set stretch to fit
wmp.stretchToFit = true; 

% Set volume to max
%   This should be hard-coded, don't make it an option. We always want the
%   player at 100% volume. 
wmp.settings.volume=100;

%% LOOP THROUGH FILES AND PLAY THEM
for trial=1:numel(X)
    
    % Need to start recordings, clear out recording variable. 
    
    % Update variables
    d.sandbox.trial = trial; 
    
    % Set the current file
    wmp.URL = X{trial};
    
    % Info on playstates here
    % http://msdn.microsoft.com/en-us/library/windows/desktop/dd564085(v=vs.85).aspx
%     display(wmp.playState); 
    
    % Wait for playback to start 
%     while isempty(strfind(wmp.playState, 'Playing')), display(wmp.playState); end     
    
    % Sit until playback has finished
%     while isempty(strfind(wmp.playState, 'Stopped')), display(wmp.playState); end     
    
    % Run modcheck after each trial 
    %   This should open the scoring interface
    
    % Run through modifiers
    for modifier_num=1:length(d.player.modifier)
    
        % Update variable in sandbox
        d.sandbox.modifier_num=modifier_num;

        % Call modifier
        %   Only run premix modifiers.
        %       This should just track mod_mixer, which isn't changing. 
        [~, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle([], mod_code, d); 

    end % for modifier_num
    [~, d]=d.player.modcheck.fhandle(d);
    
    % Get recording information, store in (growing) structure.
    
    % Clear out recording variable, start again. 
end % for i

% Close portaudio devices
PsychPortAudio('Close'); 