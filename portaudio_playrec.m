function [Y, FS]=portaudio_playrec(IN, OUT, X, FS, varargin)
%% DESCRIPTION:
%
%   Function for basic playback and recording using the PsychPortAudio
%   driver packaged with PsychToolBox 3. 
%
%   Can be used to record data for arbitrary lengths of time or perform
%   (near) simultaneous playback/recording. 
%
%   Can also be used for simple sound playback. To do this, simply provide
%   a playback device and data to play (X) and an empty field for the IN
%   parameter (recording device information). Note that there will be more
%   overhead using this function than with others, at least at the time CWB
%   wrote the help file. CWB added notes to the development section that
%   should alleviate much of this overhead (e.g., bypassing
%   InitializePsychSound, not initializing or checking keyboard buffers, 
%   etc.). This will take some work to compartmentalize and test. 
%
%   This function is a spiritual descendent of record_data written by CWB
%   in 2010. record_data used MATLAB's DAQ instead and had fewer features. 
%
% INPUT:
%
%   IN: recording device information. Can be a string or integer index into
%       return from PsychPortAudio('GetDevices'). Strings will be matched
%       to the 'DeviceName' field returned from PsychPortAudio. Make sure
%       the string matches perfectly, typos, missing characters and all.
%
%       Alternatively, IN (and OUT) can be a device structure. This is the
%       recommended format. 
%
%   OUT:    playback device information. Identical to "IN", but for sound
%           playback.
%
%   X:  NxC data matrix, where N is the number of samples and C is the
%       number of channels in the sound playback device. Note that by
%       default the output device will present sound from all available
%       channels. Add zeros to channels you do not want sound to play from.
%
%       Alternatively, X can be the path to a wav file or other data type
%       supported by AA_loaddata. 
%
%   FS: sampling rate for sound playback and recording. (default=44100)
%
%   Parameters:
%
%       'fsx':      sampling rate for data series X if X is a double or
%                   single data trace. Note that X is resampled to match FS
%                   above prior to sound playback/recording. 
%
%       'record_time':  total recording time in seconds. Useful when a
%                       fixed recording is necessary. (default = inf)
%
%       'button':       array, buttons that can be pressed to terminate a
%                       continuous recording. This can either be a
%                       character (e.g., 'a') or an keyboard index returned
%                       from KbName (e.g., 65 for 'a'). 
%
%                   Note: At the time of writing, both 'button' and
%                   'record_time' parameters must be met before the
%                   recording will be terminated. Also, in the event that
%                   sound playback is requested, sound playback must
%                   terminate before the recording will end. 
%
%       'devicetype':   integer, specifying the preferred device type. This
%                       is often useful if the user wants to select a
%                       single physical device and soud playback
%                       driver/API. Here are the Windows specific flags.
%                       Values in brackets specify order of quality and
%                       latency (1=best, 4=worst). 
%                      
%                           1: Windows/DirectSound [3]
%                           2: Windows/MME [4]
%                           3: Windows/ASIO [1]
%                           11: Windows/WDMKS [2]
%                           13: Windows/WASAPI [2] 
%
%                       For more information and additional device types,
%                       see http://docs.psychtoolbox.org/GetDevices
%
%       'rec_buffer':   the duration of the recording buffer in seconds.
%                       This should only be adjusted if the user is
%                       given an error message to extend the recording
%                       buffer length. (default = 10) Tampering with this
%                       parameter, particularly by shortening the buffer,
%                       could lead to significant problems later. Don't
%                       mess with this unless you know what you're doing. 
%                           
% OUTPUT:
%
%   Y:  recorded time series
%   FS: sampling rate of recorded time series
%
% Notes to user:
%
%   1. There is some variance in the relative initiation times of playback
%   and recording with repeated calls to portaudio_playrec. For instance,
%   CWB executed the same playback/record settings and observed shifts in
%   onset time ranging from 0.4 ms to 3.5 ms. (mean = 1.1 ms +/- 1.1 ms;
%   N=10). 
%
% Development:
%
%   1. Add support for simultaneous playback/recording from the same sound
%   card (mode 3). This will probably be helpful for Christi Miller's
%   specific circumstances. 
%
%   2. Minimize overhead for isolated sound playback. (skip
%   InitializePsychSound, remove keyboard queueing if not requested, etc.)
%
%   3. Add additional arguments for number of repetitions of the same
%   stimulus configuration. 
%
%   4. Add option to keep port audio device open (rather than closing). 
%
% Christopher W. Bishop
%   University of Washington
%   4/14

%% INPUT CHECKS AND DEFAULTS
if ~exist('IN', 'var'); IN=[]; end 
if ~exist('OUT', 'var'); OUT=[]; end 
if ~exist('X', 'var'); X=[]; end 
if ~exist('FS', 'var') || isempty(FS); FS=44100; end 
if ~exist('IN', 'var'); IN=[]; end 

% Convert parameters to structure
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

% Set recording time
%   Assume we don't have a minimum recording time by default (so set to 0).
if ~isfield(p, 'record_time') || isempty(p.record_time), p.record_time=0; end 

% Set termination button
%   No termination buttons by default
if ~isfield(p, 'button'), p.button=[]; end 

% Set default recording buffer duration
if ~isfield(p, 'rec_buffer'), p.rec_buffer=10; end 

% Massage buttons into integer values
if ~isempty(p.button)
    for i=1:length(p.button)
    
        buttons=[];
        % If it's a character, convert to integer value
        if ischar(p.button(i))
            buttons(i)=KbName(p.button(i));
        else
            buttons(i)=p.button(i); 
        end % if ischar
    
    end % for i=1:length(p.button)
    p.button=buttons; 
    clear buttons; 
end % if ~isempty(p.button)

% Create termination key matrix
%   TERMination_KEYS
term_keys=zeros(1, 256); 
term_keys(p.button)=1; 

%% CREATE BUTTON QUEUE
%   Only create a button queue if there are specific termination buttons
%   specified. 
 % so far, a termination button has not been pressed. This is checked repeatedly below. 
if ~isempty(p.button), 
    button_term=false;
    KbQueueCreate([], term_keys); 
else
    % If we aren't waiting for a button press, then we need to terminate
    % recording based on this criterion (see while loop below)
    button_term=true; 
end % if ~isempty(p.button) 
    
%% LOAD PLAYBACK DATA
%   Load time series for playback, massage into expected shape
if ~isempty(X)
    
    % Accept double/single/wav format
    t.datatype=[1 2];
    if isfield(p, 'fsx') && ~isempty(p.fsx)
        t.fs=p.fsx;
    else
        t.fs=[];
    end % if 
    [X, fs]=AA_loaddata(X, t);     
    
    % Resample output to match overall sample rate
    %   Will only be done if data are loaded from a WAV file and the sampling
    %   rates do not match. 
    if ~isempty(fs) && (fs~=FS)
        X=resample(X, FS, fs); 
    end % if ~isempty(fs)
    
end % if ~isempty(X)

%% INITIALIZE PORT AUDIO DEVICES
%   Only initialize if we can't get the devices. A crude check to reduce
%   processing overhead. 
try
    %% GET PLAYBACK AND RECORDING DEVICE NUMBER
    %   Will return the device structure for sound playback/recording. 
    [pstruct]=portaudio_GetDevice(OUT, p);
    [rstruct]=portaudio_GetDevice(IN, p); 
catch
    InitializePsychSound;
    [pstruct]=portaudio_GetDevice(OUT, p);
    [rstruct]=portaudio_GetDevice(IN, p); 
end % try/catch


%% ERROR CHECKS FOR DATA PLAYBACK
%   - Make sure we have data for all playback channels

% Make sure we have all the channel data we need to playback.
%   If we don't have enough channels, throw an error (for now). 
if ~isempty(X) && size(X,2)~=pstruct.NrOutputChannels
    error(['Playback time series must have ' num2str(pstruct.NrOutputChannels) ' channels.']);
end % if ~isempty(X) && size(X ...

%% PREPARE FOR PLAY/REC

% Initialize and fill playback buffer
if ~isempty(X)
    phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels); 
    PsychPortAudio('FillBuffer', phand, X');
end % if ~isempty(X)

% Initialize recording if specified by user. 
try rstruct.NrInputChannels
    
    % Get recording handle
    % pahandle = PsychPortAudio('Open', 2, 2, 0, freq, 2);
    rhand = PsychPortAudio('Open', rstruct.DeviceIndex, 2, 0, FS, rstruct.NrInputChannels); 

    % Allocate Recording Buffer
    PsychPortAudio('GetAudioData', rhand, p.rec_buffer); 
    
    % Get recording device status
    %   Some of these values are used later to take a better guess at the
    %   necessary recording time
    % Start recording
    %   Wait for recording to start (for real) before continuing. Helps ensure
    %   recording time (I think). 
    PsychPortAudio('Start', rhand, [], [], 1); 

    % rec_start_time is the (approximate) start time of the recording. This is
    % used to track the total recording time. 
    rec_start_time=GetSecs; 
    
    rstatus=PsychPortAudio('GetStatus', rhand);
catch 
    rhand=[];
end % try/catch

% Start Playback, if requested
Y=[]; % Recorded data
if exist('phand', 'var') && ~isempty(phand)
    
    % Start audio playback, but do not advance until the device has really
    % started. Should help compensate for intialization time. 
    PsychPortAudio('Start', phand,[], [], 1);
    
    % start_time is used for error checking below to make sure we are
    % sampling the buffer frequently enough. 
    playback_start_time=GetSecs;
    
    % Now, wait for soundplayback to start
    %   But only if we're doing sound playback. 
    pstatus=PsychPortAudio('GetStatus', phand);
    while ~pstatus.Active, pstatus=PsychPortAudio('GetStatus', phand); end 
    
else
    % If user does not want sound to playback, then set active to 0. This
    % is used in the control loop below (see while loop). 
    pstatus.Active=false;         
end % exist('phand ...

%% START BUTTON QUEUE
%   Start button queue.
if ~isempty(p.button), KbQueueStart([]); end 

%% RECORDING BUFFER CONTROL
%   Empty the recording buffer periodically.
%
%   While loop continues until all playback parameters are false. Here
%   are the parameters.
%
%       1. Sound playback must stop (pstatus.Active==0)
%       2. The minimum recording time has been exceeded
%       3. One of the termination buttons has been pressed.     
%       4. There are at least enough samples recorded to account for
%       playback latency 
%       5. rhand has to have recording device information in it. Otherwise,
%       the user does not want to record anything. So just playback the
%       sound. 
%
% Note: CWB thinks the help for 'GetStatus' incorrectly reports the
% PredictedLatency units as seconds. It's much more likely to be samples
% based on the magnitude of the values CWB has observed. 
Y=[];
while (pstatus.Active || (GetSecs - rec_start_time < p.record_time) || ~button_term  || size(Y,1) < size(X,1) + (playback_start_time - rec_start_time)*FS - ( rstatus.PredictedLatency + pstatus.PredictedLatency)) && ~isempty(rhand)
        
    % Determine start time of each loop interation.
    start_time=GetSecs; 
        
    % Gather recorded data on each loop
    %   Might need to put a check in here to make sure we aren't
    %   missing samples.
    y=PsychPortAudio('GetAudioData', rhand);            
    Y=[Y; y'];          
    
    % Look for terminating button press
    %   If any of the termination buttons have been pressed, then stop
    %   recording. 
    if ~isempty(p.button) && KbQueueCheck, button_term=true; end 
    
    % Update playback device status. 
    %   But only update if there's a valid playback handle
    if exist('phand', 'var') && ~isempty(phand)
        pstatus=PsychPortAudio('GetStatus', phand);       
    end % if ~isempty(phand)
    
end % while ...

% If we actually tried to record something, 
if ~isempty(rhand)
    display(['Record time: ' num2str(GetSecs - rec_start_time)]) 
end % if isempty(rhand)
    
% Release Keyboard queue
%   But only release it if portaudio_playrec is monitoring for button
%   presses explicitly. Often times invoking functions will monitor
%   keyboard queue as well - and we don't want to accidentally clear the
%   queue and screw something else up. 
if ~isempty(p.button), 
    KbQueueRelease;
end % if ~isempty(p.button)

% Wait for sound playback to end
while pstatus.Active, pstatus=PsychPortAudio('GetStatus', phand); end 

% Close Audio Devices
%   Should this be optional?
PsychPortAudio('Close'); 