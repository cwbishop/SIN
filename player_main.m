function [results, status]=player_main(playback_list, varargin)
%% DESCRIPTION:
%
%   This function is designed to allow adaptive audio playback. The
%   adaptive audio playback can be done in several modes and is reasonably
%   modular. The basic flow goes something like this.
%
%           1. Present a sound.
%
%           2. Collect some form of information via a modcheck (e.g., a
%           button press or scoring information)
%
%           3. Pass the output of the modcheck to a modifier
%
%           4. The modifier modifies that upcoming playback data (e.g.,
%           makes a speech stream louder)
%
%           5. The process is repeated until all stimuli are presented.
%
% INPUT:
%
%   playback_list:  cell array of the file names that the user wants to present
%               (e.g., the output from SIN_getPlaylist). 
%
% Parameters:
%
%   'bock_dur':     data block size in seconds. The shorter it is, the
%                   faster the adaptive loop is. The longer it is, the less
%                   likely you are to run into buffering problems. 
%
%   'record_mic':   bool, set to record the playback during each trial.
%                   If set and the adaptive_mode is 'bytrial', be sure that
%                   the recording device has a very long buffer (greater
%                   than the total trial + response time + a healthy
%                   window in case a subject nods off). If adaptive_mode is
%                   set to 'continuous', then the recording buffer is
%                   emptied during playback and can be much shorter.
%
%   'modcheck': function handle. This class of functions determines whether
%               or not a modification is necessary. At the time he wrote
%               this, CWB could imagine circumstances in which the same
%               modifier must be applied, but under various conditions. By
%               separating the functionality of 'modcheck' and 'modifier',
%               the user can create any combination. This should, in
%               theory, improve the versatility of the adaptive playback
%               system. 
%
%               'modcheck' can perform any type of check, but must be self
%               contained. Meaning, it (typically) cannot rely exclusively
%               on information present in the adaptive play control loop.
%               An example of a modcheck might go something like this.
%
%                   1. On the first call, create a keyboard queue to
%                   monitor for specific button presses.
%
%                   2. On subsequent calls, check the queue and determine
%                   if a specific button (or combination thereof) was
%                   pressed.
%
%                   3. If some preexisting conditions are met, then modify
%                   the signal. Otherwise, do not modify the signal.
%
%               Alternatively, a modcheck might do the following.
%
%                   1. On the first call, open a GUI with callback buttons
%                   for users to click on. 
%
%                   2. On successive calls, check to see if a button has
%                   been clicked. If it has, then return a modification
%                   code.
%
%               'modchecks' must accept a single input: a SIN options 
%               structure that has potentially been modified by
%               player_main.
%
%               modchecks must return the following variables
%                   
%                   1. mod_code:    integer (typically) describing the
%                                   nature of the required modification.
%                                   This code is further interpreted by
%                                   the modifier (below).
%
%                   2. d:   an updated structure for
%                           portaudio_adaptiveplay. 
%
%   'modifier': function handle. This class of functions will modify the
%               output signal X when the conditions of 'modcheck' (see
%               above) are satisfied. The function can do just about
%               anything, but must conform to some general guidelines.
%
%                   1. The function must accept three inputs
%
%                           X:  the time series to alter
%
%                           mod_code:   a modification code. This will
%                                       prove useful when one of several
%                                       conditional modifications are
%                                       possible (e.g., making a sound
%                                       louder or quieter). 
%
%                           d:  the control structure from
%                               portaudio_adaptiveplay.m.
%
%                   2. The function must have three outputs
%
%                           Y:  the modified time series X
%
%                           d:  the updated adaptive play structure. 
%
%   'adaptive_mode':    string, describing how the modifications should be
%                       applied to the data stream. This is still under
%                       development, but different tests (e.g., HINT and
%                       ANL) need the modifications to occur on different
%                       timescales (between words or during a continuous
%                       playback stream). The hope here is to include
%                       various adaptive modes to accomodate these needs.
%
%                           'continuous': apply modifications in as close to
%                                       real time as possible. This will
%                                       depend heavily on the size on the
%                                       'block_dur' parameter above; the
%                                       longer the block_dur, the longer it
%                                       takes for the "real time" changes
%                                       to take effect. But if the
%                                       block_dur is too short, then you
%                                       run into other, irrecoverable
%                                       problems (like buffer underruns).
%                                       Choose your poison. 
%
%                           'bytrial':      apply modifications at the end 
%                                           of each playback file. (under
%                                           development). This mode was
%                                           intended to accomodate the 
%                                           HINT.       
%
%   'playback_mode':    string, specifies one of various playback modes.
%                           'looped':   a sound is looped infinitely or
%                                       until the player receives a kill
%                                       signal from somewhere. 
%                           'standard': each sound presented once and only
%                                       once in the order dictacted by
%                                       X (although this may be randomized
%                                       if 'randomize' flag set). 
%
%   'append_files':     bool, append data files into a single file. This
%                       might be useful if the user wants to play an
%                       uninterrupted stream of files and the timing
%                       between trials is important. (true | false;
%                       default=false);
%
%                       Note: Appending files might pose some problems for
%                       established modchecks and modifiers (e.g., for
%                       HINT). Use this option with caution. 
%
%   'stop_if_error':    bool, aborts playback if there's an error. At tiem
%                       of writing, this only includes a check of the
%                       'TimeFailed' field of the playback device status.
%                       But, this can be easily expanded to incorporate all
%                       kinds of error checks. (true | false; default=true)
%
%                       Note: at time of writing, error checking only
%                       applies to 'continuous' adaptive playback. 
%
%                       Note: the 'TimeFailed' field does not increment for
%                       buffer underruns. Jeez. 
%
%                       Note: The 'XRuns' field also does not reflect the
%                       number of underruns. E-mailed support group on
%                       5/7/2014. We'll see what they say.
%
%   'startplaybackat':  double, when to start playback relative to start of
%                       sound file (sec). To start at beginning of file, st
%                       to 0. (no default)
%
%   'mod_mixer':        D x P double matrix, where D is the number of
%                       data channels (that is, the number of channels
%                       in the wav files) and P is the number of
%                       physical channels (that is, the number of
%                       output channels on the playback device). This mixer
%                       is only applied to the (potentially) modulated 
%
%                       Here are a few examples
% 
%                       Example 1: Present only the first (of two)
%                       channels from a wav file to the first (of
%                       four) output channels on the sound card
%                           [ [1; 0] [0; 0] [0; 0] [0; 0] ]
% 
%                       Example 2: Present the first (of two) channels
%                       from a wav file to the first two (of four)
%                       physical channels in equal proportions. Note
%                       that CWB chose to scale down the sounds. This
%                       is to prevent clipping. The user should use
%                       whatever fits his or her needs. 
%                           [ [0.5; 0.5] [0.5; 0.5] [0; 0] [0; 0] ]
%
%                       The mod_mixer was added relatively late in
%                       development when CWB realized it was difficult if
%                       not impossible to determine the level at which a
%                       given sound was presented. This was because
%                       different modifiers altered the data serially and
%                       each tracked its changes independently of the
%                       others. Thus, it was tough to take all of this into
%                       account post-hoc. By adding in the mixer, CWB
%                       thought it would be possible to write modifiers
%                       that change the intensity of sound playback (e.g.,
%                       modifier_dBscale) to modify a single matrix that
%                       can then be easily tracked, plotted, etc. Also,
%                       calibration factors (like RMS normalization) can
%                       also be applied directly to the mixing matrix with
%                       seamless tracking over trials/stimuli/loops. 
%
%   'playback_map': mapping parameters for the playback device. For more
%                   details, see help for map_channels.m
%
%   'record_map':   mapping parameters for the recording device. For more
%                   details, see help for map_channels.m 
%
%   'state':    player state when first launched. States may change, but
%               currently include :
%                   'run':  run the test/playback
%                   'pause': pause playback
%                   'exit':     player exits normally
%                   'error':    player exits, but in error state
%
% Windowing options (for 'continuous' playback only):
%
%   In 'continuous' mode, data are frequently ramped off or on (that is, fade
%   out or fade in) to create seamless transitions. These paramters allow
%   the user to specify windowing options, including a windowing function
%   (provided it's supported by matlab's "window" function) and a ramp
%   time.
%
%       'window_fhandle':function handle to windowing function. (default =
%                       @hann). See window.m for more options. 
%
%       'window_dur':   duration of windowing function. Too short may lead
%                       to popping or clicking in playback. Too long and
%                       it takes longer for adpative changes to occur
%                       (longer before the change "fades in"). 
%                       (seconds | default = 0.005 (5 msec))
%
% OUTPUT:
%
%   d:  data structure containing parameters and scored data. Fields depend
%       on the modifier and modcheck employed. 
%
% Development:
%
%   19. Need additional precautions when monitoring keypresses in
%   'continuous' mode. If the user starts pressing keys before sounds play,
%   we won't have any record of those button presses (at present). 
%
%   31. Modify so we can just record without playing sounds. A super dirty
%   way to do this would be to load a wavfile containing only zeros for the
%   requested duration of the recording. Might be the quickest fix. 
%
%   32. do not add data2play_mixed to the options structure until the end
%   of the experiment. During prolonged breaks, the matrix becomes very
%   large and slows the program down to the point of crashing. Why doesn't
%   MATLAB let me us pointers?!
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% Assign original input to results structure
results.UserOptions = d; 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% INITIALIZE VOICE RECORDING VARIABLE
%   Trial recordings are placed in this cell array. 
mic_recording = {}; % empty cell array for voice recordings (if specified) XXX not implemented XXX

%% SAVE DATE AND TIME 
%   Will help keep track of information later.
d.sandbox.start_time=now; 

%% SET TRIAL_COMPLETE FLAG
%   In instances when the player exits prematurely due to an error, exit
%   state, or some other modifier forcing it to end before all trials have
%   been presented, it's a good idea to keep track of which trials have
%   actually "completed" vs. those that have not.
%
%   Not quite game ready. 
% trial_complete = false(numel(playback_list)); 

% Get sampling rate for playback and recording
playback_fs = d.player.playback.device.DefaultSampleRate;
record_fs = d.player.record.device.DefaultSampleRate;

% Assign sampling rates to sandbox
d.sandbox.playback_fs = playback_fs; 
d.sandbox.record_fs = record_fs; 

%% SET PLAYER STATE 
%
%   Finite state - player can only have a single state at a time
%
%   The state is set either internally (by the player) or altered by
%   secondary functions (like a modcheck or modifier). At least in theory.
%   This was not implemented fully when CWB wrote this comment.
%   
%   state:
%       'pause':    Pause playback
%       'run':      Play or resume playback
%       'exit':     Stop all playback and exit as cleanly as possible

%% SET ADDITIONAL VARIABLES
d.sandbox.data2play_mixed=[]; 

%% LOAD DATA
%
%   1. Support only wav files. 
%       - Things break if we accept single/double data series with variable
%       lengths (can't append data types easily using SIN_loaddata). So,
%       just force the user to supply wav files. That should be fine. 
%
%   2. Resample data to match the output sample rate. 
%
% 140822 CWB: Now allows MP4 data type. This is necessary for the AV
% portion of the MLST. 
%
% Note: We want to load all the data ahead of time to minimize
% computational load during adaptive playback below. Hence why we load data
% here instead of within the loop below. 
t.datatype=[2 6];

% Store time series in cell array (stim)
stim=cell(length(playback_list),1); % preallocate for speed.
if d.player.preload
    
    for i=1:length(playback_list)    

        [tstim, fsx]=SIN_loaddata(playback_list{i}, t);
        stim{i}=resample(tstim, playback_fs, fsx); 

        % Check against mixer
        %   Only need to check against first cell of mixer because we completed
        %   an internal check on the mixer above.
        if size(d.player.mod_mixer, 1) ~= size(stim{i},2)
            error([playback_list{i} ' contains an incorrect number of data channels']); 
        end % if numel
        
    end % for i=1:length(file_list)
 
end % if d.player.preload

clear tstim fsx;

% Add file_list to d structure
d.sandbox.playback_list=playback_list;

% Append playback files if flag is set
if d.player.append_files && d.player.preload
    
    tstim=[];
    
    for i=1:length(stim)
        tstim=[tstim; stim{i}];
    end % for i=1:length(stim)
    
    clear stim;
    stim{1}=tstim; 
    clear tstim
    
end % if d.append_files

%% LOAD PLAYBACK AND RECORDING DEVICES
%   Only run InitializePsychSound if we can't load the device. Reduces
%   overhead. 
try
    % Get playback device information 
    [pstruct]=portaudio_GetDevice(d.player.playback.device);    % playback device structure
    [rstruct]=portaudio_GetDevice(d.player.record.device);      % recording device structure
catch
    InitializePsychSound; 
    [pstruct]=portaudio_GetDevice(d.player.playback.device);
    [rstruct]=portaudio_GetDevice(d.player.record.device); 
end % try/catch

% mod_mixer check
%   Need to make sure the number of columns in mod_mixer matches the number
%   of output channels
if size(d.player.mod_mixer, 2) ~= d.player.playback_map.channel_number, error('columns in mod_mixer does not match the number of output channels.'); end 

% Flag for Duplex check below (mode 3)
isDuplex=false;

% Open the playback device 
%   We now use buffered playback for both continuous and bytrial
%   adaptive playback. So, open the handle if either is selected
if isequal(d.player.adaptive_mode, 'continuous') || isequal(d.player.adaptive_mode, 'bytrial') || isequal(d.player.adaptive_mode, 'none')...
   
    if (d.player.record_mic && isempty(comp_struct(d.player.playback.device, d.player.record.device, 0))) 
        
        % Load in duplex mode (mode 3) if the recording and playback
        % devices are the same device. 
        phand = PsychPortAudio('Open', ...
            pstruct.DeviceIndex, ...
            3, ...
            0, ...
            playback_fs, ...
            [d.player.playback_map.channel_number d.player.record_map.channel_number], ...
            d.player.playback.internal_buffer, ...
            [], ...
            [d.player.playback_map.channel_map; d.player.record_map.channel_map]);
        
        % Now the recording handle is the same as the playback handle. 
        rhand = phand;
        
        % Allocate Recording Buffer
        PsychPortAudio('GetAudioData', rhand, d.player.record.buffer_dur); 
        
        % We're in duplex mode, so set the flag 
        isDuplex = true;
    else
        
        % If we don't need duplex mode, just open the device. 
        phand = PsychPortAudio('Open', ...
            pstruct.DeviceIndex, ...
            1, ...
            0, ...
            playback_fs, ...
            d.player.playback_map.channel_number, ...
            d.player.playback.internal_buffer, ...
            [], ...
            [d.player.playback_map.channel_map]);
        
%         phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, playback_fs, pstruct.NrOutputChannels, d.player.playback.internal_buffer);
    end % if (d ...
    
end % 

% Open a recording device if specified, specify as a recording device. 
%   Only open the recording device separately if we want to record and we
%   are not in duplex mode (mode 3, see above). 
if d.player.record_mic && ~isDuplex 

    % First, just try opening the recording device. If it goes well,
    % then we're done. If not, then we have work to do.

    % Open recording device
    rhand = PsychPortAudio('Open', rstruct.DeviceIndex, 2, 0, record_fs, rstruct.NrInputChannels); 

    % Allocate Recording Buffer
    PsychPortAudio('GetAudioData', rhand, d.player.record.buffer_dur); 

    % Get rstatus - we might need this later to correct for differences in
    % predicted latency
    rstatus=PsychPortAudio('GetStatus', rhand);
    
elseif ~isDuplex && ~d.player.record_mic
    
    % If we're in duplex mode, then rhand is already set above. If we're
    % not in Duplex mode and we want a recording, it's also set above. This
    % covers the last combination. 
    
    % If the user does not want to do any mic recordings, then we need to
    % set rhand to an empty array. This helps with flow control below. 
    rhand = [];
end % if d.player.record_mic

%% PLAYBACK BUFFER INFORMATION
%
%   This information is only used in 'continuous' and 'bytrial' adaptive
%   mode with auditory only stimuli. Moved here rather than below to 
%   minimize overhead (below this would be called repeatedly, but these 
%   values do not change over stimuli). 
%
%   Playback is handled differently for audiovisual adaptation. 
%
%   Use buffer information for 'bytrial' adaptive mode now as well. 
if isequal(d.player.adaptive_mode, 'continuous') || isequal(d.player.adaptive_mode, 'bytrial') || isequal(d.player.adaptive_mode, 'none')
    
    % Create empty playback buffer
    buffer_nsamps=round(d.player.playback.block_dur*playback_fs)*2; % need 2 x the buffer duration
    
    % Convert number of samples to number of seconds. Might be used below
    % for time based buffer tracking (e.g., with ASIO drivers)
    pstatus = PsychPortAudio('GetStatus', phand); 
    buffer_nsecs = buffer_nsamps/pstatus.SampleRate; 
    
    % block_nsamps
    %   This prooved useful in the indexing below. CWB opted to use a two block
    %   buffer for playback because it's the easiest to code and work with at
    %   the moment. 
    block_nsamps=buffer_nsamps/2; 

    % Convert to number of seconds. Might be used below for buffer tracking
    % (e.g., with ASIO drivers). 
    block_nsecs = block_nsamps/pstatus.SampleRate; 
    
    % Find beginning of each "block" within the buffer
    block_start=[1 block_nsamps+1];
    
    % Start filling next block after first sample of this block has been
    % played
    refillat=ceil(1/block_nsamps);
    
    % Might be used below for time based buffer tracking (e.g., with ASIO
    % drivers). 
    refillat_secs = refillat/pstatus.SampleRate;
    
end % if isequal

% Create additional fields in 'sandbox'
%   Dummy values assigned as placeholders for intialization purposes. 
d.sandbox.trial=-1; % trial number
d.sandbox.nblocks=-1; % nblocks, the block number within the trial 
d.sandbox.block_num=-1; % block number we are in. 
d.sandbox.modifier_num=[];
d.sandbox.modcheck_num=1; % hard-coded for now since code only allows a single modcheck/trial (for now)

%% INITIALIZE MODCHECK and MODIFIER
%   These functions often have substantial overhead on their first call, so
%   they need to be primed (e.g., if a figure must be generated or a sound
%   device initialized).

% Call modcheck
if ~isempty(fieldnames(d.player.modcheck))
    [mod_code, d]=d.player.modcheck.fhandle(d);
else
    % Catch in case we don't have a modcheck, but we do have modifiers.
    mod_code = [];
end

% Initialized modifiers
%   Multiple modifiers possible
for modifier_num=1:length(d.player.modifier)
    
    % Update variable in sandbox
    
    d.sandbox.modifier_num=modifier_num;
    if ~isempty(fieldnames(d.player.modifier{d.sandbox.modifier_num}))
        % Initialize modifier
        [~, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle([], mod_code, d); 
    end % if ~isempty(modifier)
    
end % for modifier_num

%% INITIALIZE BUFFER POSITION
%   User must provide the buffer start position (in sec). This converts to
%   samples
%
%   Added error check to only allow buffer start position to be set for
%   single file playback.
if d.player.startplaybackat ~= 0 && size(stim, 1) ~= 1
    error('Cannot initialize start position to non-zero value with multiple playback files');
else
    buffer_pos = round(d.player.startplaybackat.*playback_fs); 
end % if d.player ...


%% SOUND CARD WARM UP
%   CWB gleaned this from PsychPortAudioTimingTest lines 251-252. A warmup
%   may improve timing precision, especially on the first trial.
%
%   Note: this initialization procedure actually added more variance to the
%   recording length on CWB's laptop. So WEIRD! Not sure what that's about.
%   Commented out now. 
%
%   Note: CWB wants to try this again to see if the increased variance was
%   a fluke. So strange, though.

% Initialize playback device 
if ~isempty(phand)
    PsychPortAudio('FillBuffer', phand, zeros(buffer_nsamps, d.player.playback_map.channel_number)');
    PsychPortAudio('Start', phand, 0, [], 0); 
    PsychPortAudio('Stop', phand, 1);
end % if ~isempty

% Initialize recording device
if ~isempty(rhand)
    PsychPortAudio('Start', rhand, [], [], 1); 
    PsychPortAudio('Stop', rhand, 1);
end % if ~isempty(rhand)

%% INITIALIZE TRIAL COUNTER
trial = 1; 

% Decided to use a variable to store this information for easy modification
% by modifier_append2playlist. 
number_of_trials = numel(stim); 
d.sandbox.number_of_trials = number_of_trials; 

while trial <= number_of_trials

    
    %% BUFFER POSITION
    if trial == 1
        buffer_pos = buffer_pos + 1; % This starts at the first sample specified by the user.     
    else
        % Note: this might not be appropriate for 'looped' playback mode,
        % but CWB has not encountered this specific situation yet and thus
        % has not dedicated much thought to it. 
        buffer_pos = 1; % start the buffer at beginning of the next stimulus
    end % if trial == 1 ...
        
    %% UPDATE TRIAL IN SANDBOX
    %   d.sandbox.trial is used by other functions
    d.sandbox.trial = trial; 
    
    %% EMPTY RECORDING
    rec=[]; 
    
    %% SELECT APPROPRIATE STIMULUS
    %   SIN_loaddata will either kick back the (preloaded) audio tracks, or
    %   will attempt to load the file
    X = stim{trial}; 
%     X = SIN_loaddata(stim{trial}, 'fs', playback_fs);     
    
    % By file modcheck and data modification. 
    %   We check at the beginning of each "trial" and scale the upcoming
    %   sound appropriately. 
    if isequal(d.player.adaptive_mode, 'bytrial')
                
        % Call modcheck     
        %   Call modcheck at end of trial to keep referencing sensible. 
        for modifier_num=1:length(d.player.modifier)
    
            % Update variable in sandbox
            d.sandbox.modifier_num=modifier_num;
    
            % Initialize modifier
            if ~isempty(fieldnames(d.player.modifier{d.sandbox.modifier_num}))
                [Y, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle(X, mod_code, d); 
                
                % Check for for exit/error status after each modifier, if
                % the user tells us to. CWB found this useful when trying
                % to exit before certain modifications take place. 
%                 if d.player.checkaftermod
%                     if isequal(d.player.state, 'exit') || isequal(d.player.state, 'error')
%                         break
%                     end % isequal(d.player.state, 'exit');
%                 end % if d.player.checkaftermodifier
                
            end % if modifier
    
        end % for modifier_num                

    else
        % Assign X (raw data) to second variable for playback 
        Y=X; 
    end % isequal(d.player.adaptive_mode, 'bytrial')     
    
    % Safeguard for basic sound playback when there are no modchecks or
    % modifiers.     
    if ~exist('Y', 'var'), Y=X; end 
    
    % We'll update this on every iteration just in case a modifier has
    % appended stimulus information (e.g., if modifier_append2playllist is
    % called). This must occur *after* modifiers are called in case the
    % modifiers change something about the number of trials (e.g., updates
    % the stimulus, etc.). 
    number_of_trials = numel(stim); 
    d.sandbox.number_of_trials = number_of_trials; 
    
    % Exit playback loop if the player is in exit state
    %   This break must be AFTER rec transfer to
    %   d.sandbox.mic_recording or the recordings do not
    %   transfer. 
    %
    %   The beginning of the next trial is "AFTER" rec transfer. 
    if isequal(d.player.state, 'exit') || isequal(d.player.state, 'error')
        break
    end % isequal(d.player.state, 'exit');
    
    % Global prep, indepdent of PlayerType
    % rhand is empty if record_mic == false. 
    if ~isempty(rhand)
        rstatus=PsychPortAudio('GetStatus', rhand);
    end % if ~isempty(rhand)
    
    % Start recording device
    %   Just start during the first trial. This will be emptied
    %   after every trial. Should not need to restart the recording
    %   device. 
    if d.player.record_mic && trial == 1 && isequal(d.player.state, 'run') && ~rstatus.Active ...
            && ~isDuplex % recording will start along with playback below if we're in duplex mode. So don't need to execute this.

        % Last input (1) tells PsychPortAudio to not move forward
        % until the recording device has started. 
        PsychPortAudio('Start', rhand, [], [], 1); 

        % rec_start_time is the (approximate) start time of the recording. This is
        % used to track the total recording time. 
        rec_start_time=GetSecs;
        rec_block_start=rec_start_time; 

    end % if d.player.record_mic
    
    % Switch statement determines which playback mode should be used.
    %   - PTB (Streaming): PsychToolBox (PTB) is used and data are streamed
    %   a block at a time. Designed for use with 'continuous' adaptive
    %   mode.
    switch lower(d.player.playertype)
        
        case {'ptb (stream)'} 
    
            %% CREATE WINDOWING FUNCTION (ramp on/off)
            %   This is used for continuous adaptive mode. The windowing function can
            %   be provided by the user, but it must be a function handle accepted
            %   by MATLAB's window function.    
            win=window(d.player.window_fhandle, round(d.player.window_dur*2*playback_fs)); % Create onset/offset ramp

            % Match number of data_channels
            %   data_channels are ramped and mixed to match the number of
            %   physical_channels below. 
            win=win*ones(1, size(X,2)); 
    
            % Create ramp_on (for fading in) and ramp_off (for fading out)
            ramp_on=win(1:ceil(length(win)/2),:); ramp_on=[ramp_on; ones(block_nsamps - size(ramp_on,1), size(ramp_on,2))];
            ramp_off=win(ceil(length(win)/2):end,:); ramp_off=[ramp_off; zeros(block_nsamps - size(ramp_off,1), size(ramp_off,2))];    
            
            % nblocks            
            if isequal(d.player.playback_mode, 'looped')
                nblocks=inf;
            elseif isequal(d.player.playback_mode, 'standard')
                nblocks=ceil(size(X,1)./size(ramp_on,1)); 
            else
                error(['Unknown playback_mode: ' d.player.playback_mode]); 
            end % if
            
            % Store nblocks in sandbox. This is needed by some modcheck
            % functions for termination purposes (e.g.,
            % ANL_modcheck_keypress)
            d.sandbox.nblocks=nblocks; 
            
            % initiate block_num
            block_num=1;
            
            % Loop through each section of the playback loop. 
            %% THIS IS THE SPLICE POINT FOR AV/AUDITORY ONLY PLAYBACK
            while block_num <= nblocks
                
                % Start recording device
                %   This second check had to be moved here as well since
                %   stimuli may be started in the "pause" phase for ptb
                %   (stream). 
                if d.player.record_mic && trial == 1 && isequal(d.player.state, 'run') && ~rstatus.Active ...
                        && ~isDuplex % recording will start along with playback below if we're in duplex mode. So don't need to execute this.

                    % Last input (1) tells PsychPortAudio to not move forward
                    % until the recording device has started. 
                    PsychPortAudio('Start', rhand, [], [], 1); 

                    % rec_start_time is the (approximate) start time of the recording. This is
                    % used to track the total recording time. 
                    rec_start_time=GetSecs;
                    rec_block_start=rec_start_time; 

                end % if d.player.record_mic
                
                % Store block number in sandbox - necessary for some
                % termination procedures
                d.sandbox.block_num = block_num; 
                
                % Store buffer position
                d.sandbox.buffer_pos = buffer_pos; 
                
                % Which buffer block are we filling?
                %   Find start and end of the block                
                startofblock=block_start(1+mod(block_num-1,2));
                
                % Might be used below for time based tracking of buffer
                % position (e.g., with ASIO drivers) 
                startofblock_nsecs = startofblock/pstatus.SampleRate; 
                
                % Load data using logical mask
                %   There is a special case when the logical mask is split
                %   - as in 110011. This occurs when the sound is not an
                %   even multiple of the block_dur setting (block_nsamps in
                %   main body of code). 
                %
                %   We want to do different things based on the playback
                %   mode. 
                %       'looped':           if this is true, then we want
                %                           to load the samples at the end
                %                           of the sound, then load the
                %                           samples at the beginning of the
                %                           sound (circular buffer type of
                %                           a deal).
                %
                %       'standard': just load the samples at the end of the
                %                   sound and zeropad the rest to fill the
                %                   buffer. 
                
                % If we don't have enough consecutive samples left to load
                % into buffer, then we need to do one of two things
                %
                %   1. Beginning loading sound from the beginning of the
                %   file again.
                %
                %   2. Load what we have and add zeros to make up the
                %   difference. 
                if buffer_pos + buffer_nsamps > size(Y,1)
                    
                    % Load data differently
                    if isequal(d.player.playback_mode, 'looped')
                        % If looped, then loop to load beginning of sound.
                        data=[Y(buffer_pos:end,:); Y(1:buffer_nsamps-(size(Y,1)-buffer_pos)-1,:)];
                    else
                        data=[Y(buffer_pos:end,:); zeros(buffer_nsamps-(size(Y,1)-buffer_pos)-1, size(Y,2))]; 
                    end % if d.player.looped_payback
                    
                else
                    data=Y(buffer_pos:buffer_pos+buffer_nsamps-1, :); 
                end % if any(dmask-1)
                
                % Modcheck and modifier for continuous playback
                if isequal(d.player.adaptive_mode, 'continuous')
                    
                    % Check if modification necessary
                    [mod_code, d]=d.player.modcheck.fhandle(d); 
                    
                    % Modify main data stream
                    %   Apply all modifiers. 
                    for modifier_num=1:length(d.player.modifier)
    
                        % Update variable in sandbox
                        d.sandbox.modifier_num=modifier_num;
    
                        % Call modifier
                        %   Only run premix modifiers
                        if ~isempty(fieldnames(d.player.modifier{modifier_num})) && isequal(d.player.modifier{d.sandbox.modifier_num}.mod_stage, 'premix')
                            [data, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle(data, mod_code, d); 
                        end % if isequal
                            
                    end % for modifier_num
                                        
                end % if isequal ...       
                
                % Ramp new stream up, mix with old stream. 
                %   - The mixed signal is what's played back. 
                %   - We don't want to ramp the first block in, since the
                %   ramp is only intended to fade on block into the next in
                %   a clean way. 
                %   - 140523 CWB adds in an additional check. We want to
                %   fade sound in, even if it's the first block_num, if the
                %   buffer_position has been set to some other starting
                %   point. This way, if we start in the middle of a sound,
                %   we're less likely to encounter transients.
                if block_num==1 && buffer_pos==1
                    data2play=data(1:block_nsamps, :);
                elseif block_num==1 && buffer_pos~=1
                    data2play=data(1:block_nsamps, :).*ramp_on;
                else
                    % Fade out previous setting (x) and fade in the new
                    % data (first half of data). 
                    data2play=data(1:block_nsamps, :).*ramp_on + x.*ramp_off; 
                end % if block_num==1
                
                % Mix data into corresponding channels
                %   Each cell corresponds to a physical output channel.
                %   Each element with each cell corresponds to a column of
                %   data2play.
                data2play_mixed = data2play*d.player.mod_mixer;
                
                % Save second buffer block for fading on the next trial.
                %   Zero padding to make x play nicely when we're at the
                %   end of a sound                 
                x=[data(1+block_nsamps:end, :); zeros(block_nsamps-size(data(1+block_nsamps:end, :),1), size(data,2))]; 
                
                % Basic clipping check
                %   Kill any audio devices when this happens, then throw an
                %   error. 
                if max(max(abs(data2play_mixed))) > 1 && d.player.stop_if_error, 
                    warning('Signal clipped!'); 
                    d.player.state='error'; 
                    break % exit and return variables to the user. 
                end % if max(max(abs(data))) > 1
                    
                % Post-mixing modifiers
                %   Some modifiers need to be run AFTER mixing. For
                %   instance, an inline digital filter to correct the
                %   frequency response and levels of audio drivers (e.g.,
                %   speakers) would need to be applied AFTER mixing.
                for modifier_num=1:length(d.player.modifier)

                    % Update variable in sandbox
                    d.sandbox.modifier_num=modifier_num;

                    % Call modifier
                    %   Only run premix modifiers
                    if ~isempty(fieldnames(d.player.modifier{modifier_num})) && isequal(d.player.modifier{d.sandbox.modifier_num}.mod_stage, 'postmix')
                        [data2play_mixed, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle(data2play_mixed, mod_code, d); 
                    end % if isequal

                end % for modifier_num
                
                % Save playback data
                %   Data piped to the speakers are saved. This makes it
                %   easier for users to playback what was presented to each
                %   speaker at the commandline (using audioplayer or
                %   wavplay or some other variant). 
                %
                %   Had to disable this due to memory constraints.
                d.sandbox.data2play_mixed=[d.sandbox.data2play_mixed; data2play_mixed]; 
                
                % Get playback device status
                pstatus=PsychPortAudio('GetStatus', phand);
                
                % First time through, we need to start playback
                %   This has to be done ahead of time since this defines
                %   the buffer size for the audio device.                 
                %
                %   Added additonal check so we only initialize the sound
                %   card ONCE. 
                %
                %   Added a 'run' state check. We don't want to start
                %   playback until the player is in the run state. 
                if block_num==1 && ~pstatus.Active && isequal(d.player.state, 'run')
                   
                    % Start audio playback, but do not advance until the device has really
                    % started. Should help compensate for intialization time. 
        
                    % Fill buffer with zeros
                    PsychPortAudio('FillBuffer', phand, zeros(buffer_nsamps, d.player.playback_map.channel_number)');
                    
                    % Add one extra repetition for a clean transition.
                    % Note that below we wait for the second buffer block
                    % before we fill the first, so we end up losing a
                    % single playthrough the buffer. This could be handled
                    % better, but CWB isn't sure how to do that (robustly)
                    % at the moment.
                    %
                    %   CWB changed so all playback modes have "infinite"
                    %   playback loops. This way the user can 'pause'
                    %   playback even in 'standard' playback_mode without
                    %   running out of playback cycles. The while loop now
                    %   controls the termination of playback rather than
                    %   the player itself.
                    PsychPortAudio('Start', phand, 0, [], 0);      
                    
                    playback_start_time = GetSecs; % Get approximate playback start time 
                    
                    % If we are running a device in full duplex mode, then
                    % we need to tell portaudio_adaptiveplay when the
                    % recording block starts.                    
                    if isDuplex
                        rec_block_start = playback_start_time;
                        rec_start_time = playback_start_time; 
                    end % if isDuplex
                    
                    % Wait until we are in the second block of the buffer,
                    % then start rewriting the first. Helps with smooth
                    % starts 
                    pstatus=PsychPortAudio('GetStatus', phand); 
                    t = GetSecs; % get the current time
                    while mod(t - playback_start_time, buffer_nsecs) - block_start(2)/pstatus.SampleRate < refillat_secs
                        t = GetSecs;
                    end % while 
                    
                    % We need to get pstatus again here. This is important
                    % for the first playthrough, especially with ASIO
                    % drivers which seem to update slower-than-normal. So,
                    % after we loop, grab the status again. 
                    pstatus=PsychPortAudio('GetStatus', phand); 
                    
                end % if block_num==1               
    
                % Load data into playback buffer
                %   CWB tried specifying the start location (last parameter), but he
                %   encountered countless buffer underrun errors. Replacing the start
                %   location with [] forces the data to be "appended" to the end of the
                %   buffer. For whatever reason, this is far more robust and CWB
                %   encountered 0 buffer underrun errors.                 
                
                % Only try to fill the buffer if the player is in run state
                %   Perhaps this should be changed to monitor the
                %   pstatus.Active field?? Might lead to undetected errors
                %   ... 
                if pstatus.Active
                    PsychPortAudio('FillBuffer', phand, data2play_mixed', 1, []);  
                end % if isequal ...                

                % Shift mask
                %   Only shift if the player is in the 'run' state.
                %   Otherwise, leave the mask as is. 
                %
                %   Note: This must be placed after the modcheck/modifier
                %   above (in continuous mode) or we run into a
                %   'stuttering' effect. This is due to the mask being
                %   improperly moved. 
                if isequal(d.player.state, 'run')
                    
                    % There are definitely "cooler" ways to do move the
                    % window of samples to load (CWB loves the idea of
                    % using a circularly shifted logical mask), but they
                    % were prohibitively slow. So, CWB had to go with a
                    % straightforward (and not so pretty) solution. 
                    buffer_pos=mod(buffer_pos+block_nsamps, size(Y,1)); 

                end % isequal(d.player.state, 'run'); 
                
                pstatus=PsychPortAudio('GetStatus', phand);

                % Now, loop until we're half way through the samples in 
                % this particular buffer block.
                t = GetSecs; % get the current time
                while mod(t, buffer_nsecs) - startofblock_nsecs < refillat_secs ...
                        && isequal(d.player.state, 'run')                    
                    t = GetSecs;                    
                end % while ...
                
                % Error checking after each loop
                %   For some reason, using ASIO drivers always leads to a
                %   buffer underrun during first playthrough. So, for now,
                %   CWB hard coded the exception here
                if d.player.stop_if_error && (pstatus.XRuns > 1)
                    warning('Error during sound playback. Check buffer_dur and internal_buffer.'); 
                    d.player.state='error';
                    break 
                end % if d.player.stop ....
                
                % Zero out the second buffer block if we happen to end in
                % the first. 
                %   If this is not done, whatever was left in the second
                %   buffer block is played back again, which creates an
                %   artifact. 
                %
                %   Note: This probably shouldn't be applied in "looped
                %   playback" mode, but CWB needs to think about it more.
                %   XXX
%                 if block_num==nblocks && startofblock==block_start(1)
                if block_num==nblocks 
                    
                    % Fill the next block with zeros.
                    PsychPortAudio('FillBuffer', phand, zeros(block_nsamps, size(data2play_mixed,2))', 1, []);  
                    
                    % Now wait until we start in the next block of the
                    % buffer, then fill the remaining samples with zeros.
                    % The conditional checks are not very intuitive to CWB,
                    % but seem to work. 
                    t = GetSecs; % get the current time   
                    while mod(t, buffer_nsecs) - startofblock_nsecs < block_nsecs ... 
                            && mod(t, buffer_nsecs) - startofblock_nsecs > 0 ...
                        && isequal(d.player.state, 'run')  
                        t = GetSecs;                    
                    end % while ...
                
                    % Fill the remaining samples with zeros
                    PsychPortAudio('FillBuffer', phand, zeros(block_nsamps, size(data2play_mixed,2))', 1, []);                    
                    
                end % if block_num==nblocks
                
                % Empty recording buffer frequently
                %   Only empty if the recording device is active and the
                %   user wants us to gather recorded responses. 
                if ~isempty(rhand)
                    rstatus = PsychPortAudio('GetStatus', rhand);
                end % rstatus
                
                if d.player.record_mic && rstatus.Active
                    
                    % Check to make sure we are checking our buffer faster
                    % enough
                    if GetSecs - rec_block_start > d.player.record.buffer_dur
                        error('Recording buffer too short'); 
                    end 
                    
                    % empty buffer
                    trec=PsychPortAudio('GetAudioData', rhand)';
                    
                    % Empty recording buffer, if necessary. 
                    rec=[rec; trec]; 
                    
                    % Error check for clipping
                    if any(any(abs(trec)>=1)) && d.player.stop_if_error
                        warning('Recording clipped!');
                        d.player.state='error';                        
                    end % 
                        
                    % Reset recording time
                    rec_block_start=GetSecs; 
                    
                end % d.player.record_mic
            
                % Only increment block information if the sound is still
                % being played. 
                if isequal(d.player.state, 'run')
                    
                    % Increment block count
                    block_num=block_num+1; 
                    
                end % if isequal ...
                
                % Clear mod_code
                %   Important if playback is paused for any reason. Do not
                %   want the mod_code applying to the same sound twice. 
                clear mod_code;
                
                % If player state is in 'exit', then stop all playback and
                % return variables.
                %
                % Do the same if we are in an 'error' state
                if isequal(d.player.state, 'exit') || isequal(d.player.state, 'error')
                    break; 
                end % 
            end % while
            
            % Grab the last known buffer position within our two-block
            % playback buffer.
            end_block_pos = mod(pstatus.ElapsedOutSamples, buffer_nsamps) - block_start(block_start~=startofblock); % tells us where we were in the block the last time we checked
            end_OutSamples = pstatus.ElapsedOutSamples; % tells us how many samples total have played
            
            % Wait until we hit the first sample of what would be the next
            % block, then stop playback. This ensures all samples are
            % presented before soundplayback is terminated. 
            %   - CWB ran into issues with sounds being cut short with long
            %   block_dur(ations) (e.g., 0.4 s). This was not obvious with
            %   shorter block lengths.
            %             while mod(pstatus.ElapsedOutSamples, buffer_nsamps) - startofblock >= end_pos ...                         
            %
            %   - CWB left this wait loop unchanged (see notes on ASIO
            %   drivers above). This is because it shouldn't end before the
            %   end of the buffer, so we shouldn't get any pops or clicks.
            %   CWB wanted to take advantage of this "bug" for smooth
            %   endings.
            while buffer_nsamps - end_block_pos > pstatus.ElapsedOutSamples - end_OutSamples ...
                    && isequal(d.player.state, 'run') % we don't want to loop and wait forever if the player isn't running. 
                pstatus=PsychPortAudio('GetStatus', phand);             
            end % while
            
            % Schedule stop of playback device.
            %   - Should wait for scheduled sound to complete playback.
            %   - BUT, we DON'T want to stop if we are recording and in
            %   duplex mode            
            if ~isDuplex || ~d.player.record_mic
                if isequal(d.player.state, 'run')
                    PsychPortAudio('Stop', phand, 1);
                elseif isequal(d.player.state, 'exit') || isequal(d.player.state, 'error')
                    PsychPortAudio('Stop', phand, 0);                                
                end % if isequal ...             
            end % if ~isDuplex || ~d.player.record_mic
            
        case {'ptb (standard)'}
            
            % Use PsychToolBox (PTB) to present sounds. Unlike PTB
            % streaming, sound data are loaded into buffer entirely, rather
            % than block by block. This should circumvent some (rare)
            % instances of buffer underrun errors. 
            
            % CWB used BasicSoundScheduleDemo as an example of sound
            % playback. 
            
            % create data2play
            data2play_mixed =Y*d.player.mod_mixer;
            
            % We do something SLIGHTLY different if we want recordings to
            % work properly. Recall that there will be some inherent delay
            % in sound playback/recording. So, we need to delay the stop
            % time a bit. To do that, we'll pad the playback buffer by the
            % required number of samples (zero it out).
            
%             pstatus=PsychPortAudio('GetStatus', phand);  
            if ~isempty(rhand)
                % The predicted latency ended up being too conservative an
                % estimate in many cases (e.g., at UofI), so CWB wrote a
                % condition to pick the longer of two possibilities : the
                % sum of the predicted latencies, or the sum of the buffer
                % lengths. With ASIO drivers, the latter will usually be
                % larger.                 
                lat = max([ ...
                    pstatus.PredictedLatency + rstatus.PredictedLatency, ...
                    (pstatus.BufferSize./playback_fs + rstatus.BufferSize./record_fs)]);
                
            elseif ~isempty(phand)
                % As above, we want to set add an appropriate wait time. 
                lat = max([ ...
                    pstatus.PredictedLatency, ...
                    pstatus.BufferSize./playback_fs]);
            else 
                lat = 0; 
            end % isempty(rhand
            
            % Convert lat (sec) to samples
            lat = ceil(lat * playback_fs); 
%             lat = ceil(lat*1.05 * playback_fs);             
            
            % Add zeros to end 
            data2play_mixed = [data2play_mixed; zeros(lat, size(data2play_mixed,2))];  %#ok<AGROW>
            
            % Append data to sandbox variable
            d.sandbox.data2play_mixed=[d.sandbox.data2play_mixed; data2play_mixed]; 
            
            % Create a sound buffer for each trial 
            buffer = PsychPortAudio('CreateBuffer', [], data2play_mixed');
            
            % Fill playback buffer with our data
            PsychPortAudio('FillBuffer', phand, buffer);
            
            % Start playback, single repetition.
            PsychPortAudio('Start', phand, 1, [], 1); 
            
            % Estimate start of playback
            playback_start_time = GetSecs;
            
            % If we're in Duplex mode, then we need to populate these
            % fields here. 
            if isDuplex
                rec_block_start = playback_start_time;
                rec_start_time = playback_start_time; 
            end % if isDuplex
            
            % Stop, but only after sound is complete. 
            PsychPortAudio('Stop', phand, 1);             
            
        case {'wmp'}  
            
            % The WMP player type uses ActiveX controls to present stimuli
            % through WMP.
            %
            % Note: WMP still uses PTB to present continuous masking noise,
            % if that information is provided to the player.
                        
            %% FILL BUFFER AND START NOISE PLAYBACK
            % Fill the playback buffer
            if trial == 1
                
                %% LOAD NOISE
                %   Load using SIN_loaddata
                %   Mix using noise_mixer field
                [noise, nfs] = SIN_loaddata(d.player.contnoise); 
                
                %% MULTIPLY NOISE BY NOISE MIXER
                data2play_mixed = noise*d.player.noise_mixer; 
                
                %% RESAMPLE NOISE TO SAMPLING RATE OF PLAYBACK DEVICE
                data2play_mixed = resample(data2play_mixed, playback_fs, nfs);
                clear nfs
                
                % Save data2play_mixed to sandbox field
                d.sandbox.data2play_mixed=[d.sandbox.data2play_mixed; data2play_mixed]; 
                
                buffer = PsychPortAudio('CreateBuffer', [], data2play_mixed');
                
                PsychPortAudio('FillBuffer', phand, buffer);

                % This starts playback and recording if we're in duplex mode. 
                %   - Fifth input set to 1, so we wait for start of
                %   playback before we return control. 
                PsychPortAudio('Start', phand, 0, [], 1);           

                % Get (approximate) start time of player
                playback_start_time = GetSecs; % Get approximate playback start time 
            
                % If we're in Duplex mode, then we need to populate these
                % fields here. 
                if isDuplex
                    rec_block_start = playback_start_time;
                    rec_start_time = playback_start_time; 
                end % if isDuplex
            
            else
                % Need to track start of trial (a "block" here) 
                rec_block_start = GetSecs; 
            end % if trial == 1
            
            % Ampersand necessary to run as a background command. Otherwise
            % the first call will hang if wmplayer is not already open. 
            cmd = ['wmplayer "' playback_list{trial} '" &'];
            SIN_runsyscmd([], 'cmd', cmd); % calls a slightly different player, SIN runsyscmd, to handle wmplayer.
            
            %% BRING FIGURE TO FOREGROUND
            %   If scoring GUI is open, it might have covered up the video.
            %   This might not be a good fix if video and scoring are on
            %   the same screen ...
%             figure(wmpactxfig); 
            
            %% LOAD FILE INTO WMP
            % Set the current file
%             wmp.URL = playback_list{trial};            
            
            % Play movie
%             wmp.control.play();        

        otherwise
            
            error(['Unknown adaptive mode (' d.player.adaptive_mode '). See ''''adaptive_mode''''.']); 
            
    end % switch d.player.adaptive_mode

    % Basic clipping check
    %   Kill any audio devices when this happens, then throw an
    %   error. 
    if max(max(abs(data2play_mixed))) > 1 && d.player.stop_if_error, 
        warning('Signal clipped!'); 
        d.player.state='error'; 
        break % exit and return variables to the user. 
    end % if max(max(abs(data))) > 1
    
    % Run the modcheck, but only if it's 'bytrial'. 
    if isequal(d.player.adaptive_mode, 'bytrial')

        % Call modcheck, but only if there's one to call
        if ~isempty(fieldnames(d.player.modcheck))
            [mod_code, d]=d.player.modcheck.fhandle(d);
        end
    end % if isequal( ...     
    
    % Go ahead and update the player and recording device information.     
    pstatus=PsychPortAudio('GetStatus', phand);
    
    if ~isempty(rhand)
        rstatus=PsychPortAudio('GetStatus', rhand);
    end % if ~isempty(rhand)
    
    % Only empty recording buffer if user tells us to
    %   Recording device does NOT need to be active in order to do this. 
    %
    %   added in rec_start_time check to deal with instances when the
    %   recording device has not been started. This replaced rstatus.Active
    %   because rstatus.Active was an unreliable flag for duplex
    %   recordings. 
    if d.player.record_mic && exist('rec_start_time', 'var') % && rstatus.Active

        % Wait for a short time to compensate for differences in
        % relative start time of the recording and playback device.
        % After the wait, empty the buffer again. Now rec should
        % contain all of the signal + some delay at the beginning
        % that will need to be removed post-hoc in some sort of
        % sensible way. This is not a task for
        % portaudio_adaptiveplay. 
        WaitSecs(rec_start_time-playback_start_time);

        pstatus=PsychPortAudio('GetStatus', phand);
        rstatus=PsychPortAudio('GetStatus', rhand);

        % Check to make sure we are checking our buffer fast
        % enough                
        if GetSecs - rec_block_start > d.player.record.buffer_dur
            error('Recording buffer too short'); 
        end % if GetSecs ...

        % Empty recording buffer, if necessary. 
        % empty buffer
        trec=PsychPortAudio('GetAudioData', rhand)';

        % Empty recording buffer, if necessary. 
        rec=[rec; trec]; 

        % Error check for clipping
        if any(any(abs(trec)>=1)) && d.player.stop_if_error
            warning('Recording clipped!');
            d.player.state='error';                        
        end %                 

        % Save recording to sandbox
        mic_recording{trial} = rec;  %#ok<AGROW>
        clear rec; % just to be safe, clear the variable

    end % if d.player.record_mic
    
    % Stop device if we're in duplex mode
    %   - However, do NOT want to stop if we are configured to run
    %   continuous noise. This is getting confusing ... 
    if isDuplex && ~isfield(d.player, 'contnoise') && isempty(d.player.contnoise)
        PsychPortAudio('Stop', phand, 0);
    end % if isDuplex
     
    %% INCREMENT TRIAL COUNTER
    trial = trial + 1; 
    
end % while trial < numel(stim)

% Close all open audio devices
PsychPortAudio('Close');

% Copy over recordings
d.sandbox.mic_recording = mic_recording; 
clear mic_recording; 

% Attach end time
d.sandbox.end_time=now; 

% Attach stim variable
%   Decided not to do this since we already have the play list. But it
%   might be useful to kick back the data that are actually presented - so
%   we have a record of what was actually fed to the sound card after all
%   filtering, etc. is done. 
%
%   CWB decided this would be a good idea since the files on disk might
%   CHANGE. If they change, we're hosed. So, attach the actual data to the
%   structure and use that. This was a particularly glaring issue with
%   Hagerman recordings. 
d.sandbox.stim = stim; 

% Clear stim for memory saving
clear stim

% Attach (modified) structure to results
%   This is returned to the user. 
results.RunTime = d; 

% Assign status variable
status = d.player.state; 