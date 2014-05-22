function results=portaudio_adaptiveplay(X, varargin)
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
%   X:  cell array of file names to wav files. 
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
%   'randomize':    bool, set to shuffle X (the playback list) before
%                   beginning adaptive play. 
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
%               'modchecks' must accept a single input; a master structure
%               contained by portaudio_adaptiveplay. 
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
%   'playback_channels':    integer array. Each element determines which
%                           channels the corresponding column of the
%                           playback file (elements of X) will be assigned
%                           to. 
%
%   'looped_playback':  bool, if set then the playback_list (X) is 
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
% Unmodulated sound playback settings:
%
%   CWB originally tried to setup a slave device to manage a second audio
%   buffer, but after some basic tests, it became clear that the audio
%   playback quality was just too low. In fact, most attempts, even simply
%   playing back a sound of interest, crashed MATLAB completely. This
%   solution was not stable. So, CWB opted to allow users to grab a second
%   handle (and buffer) to the same physical device. Although this is not
%   strictly a "slave", it allows the user to present a sound that will not
%   be subjected to modchecks and modifiers. 
%
%   This addition was intended to allow the user to present a masker during
%   sound playback that would *not* be subjected to modchecks and
%   modifiers. 
%
%   At time of writing, only a single file can be presented as an
%   unmodulated sound. That is, the same sound is presented for each
%   element of X or, if unmod_playbackmode is set to 'looped', is looped
%   continuously throughout playback. 
%
%       'unmod_playback':   A single-element cell containing the filename
%                           of the wavfile to be be presented.
%
%       'unmod_channels':   a channel array similar to the
%                           'playback_channels' paramter described above,
%                           but 'slave_channels' only applies to the file
%                           specified by 'slave_playback'. (defaults to
%                           playback_channels)
%       
%       'unmod_playbackmode':   string, the method of unmod playback. This
%                               is still under development.
%                               (default='')
%                                   'looped':   Loop unmod playback. This
%                                               is useful when a masker
%                                               needs to be presented
%                                               constantly throughout an
%                                               otherwise independently
%                                               controlled target stream
%                                               (e.g., with HINT).
%
%                                   'stopafter':Stop the unmodulated noise
%                                               after each trial. If this
%                                               is set, both unmod_leadtime
%                                               and unmod_lagtime need to
%                                               be set. 
%
%       'unmod_leadtime':   double, how far in advance the slave device
%                           should be started relative to the modulated
%                           playback stream. (default=0 seconds). 
%                           This proved useful when administering the HINT. 
%                           This is implemented, but terribly crude and
%                           should not be used for precisely controlled
%                           relative timing (yet)
%
%       'unmod_lagtime':    Double, how long after modulated playback has
%                           stopped before stopping the unmodulated
%                           playback (secs) See notes on timing control for
%                           unmod_leadtime; same deal here - things aren't
%                           terribly precise yet. 
%       
% OUTPUT:
%
%   d:  data structure containing parameters and scored data. Fields depend
%       on the modifier and modcheck employed. 
%
% Development:
%
%   1. Add timing checks to make sure we have enough time to do everything
%   we need before the buffer runs out
%
%   4. Add continuously looped playback (priority 1). 
%
%   12. Always modify originally provided data. This will prevent, in
%   extreme cases, digital quantization error that could lead to bizaree
%   playback situations.
%
%   13. Improve d.unmod_leadtime so the relative start times are reasonably
%   close. 
%
%   14. Add option to record playback from a recording device. Write data
%   to file or data structure (not sure which is more helpful yet). 
%
%   15. How do we terminate playback at an arbitrary time?
%
%   18. change unmod_playbackmode names to something more informative. 
%
%   19. Need additional precautions when monitoring keypresses in
%   'continuous' mode. If the user starts pressing keys before sounds play,
%   we won't have any record of those button presses (at present). 
%
%   20. Recorded responses are cut a little short. Most obvious in
%   continuous mode (tested with ANL). At the time, the recording device
%   had a delay of ~465 ms (MME)while playback had a delay of ~120 ms
%   (Windows Direct Sound). Probably need to compensate for any latency
%   differences to ensure high-fidelity (and complete) recordings. CWB
%   tried using "Direct Sound" recordings, but they were very crackly and
%   low quality. 
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

%% RANDOMIZE PLAYBACK LIST
playback_list=X; 
if d.player.randomize
    
    % Seed random number generator
    rng('shuffle', 'twister');
    
    % Shuffle playlist
    playback_list={playback_list{randperm(length(playback_list))}}; 
end % if d.player.randomize

%% INITIALIZE VOICE RECORDING VARIABLE
%   Trial recordings are placed in this cell array. 
d.sandbox.voice_recording = {}; % empty cell array for voice recordings (if specified) XXX not implemented XXX

%% SAVE DATE AND TIME 
%   Will help keep track of information later.
d.sandbox.start_time=now; 

% Get sampling rate for playback
FS = d.player.playback.fs; 

%% LOAD DATA
%
%   1. Support only wav files. 
%       - Things break if we accept single/double data series with variable
%       lengths (can't append data types easily using SIN_loaddata). So,
%       just force the user to supply wav files. That should be fine. 
%
%   2. Resample data to match the output sample rate. 
%
% Note: We want to load all the data ahead of time to minimize
% computational load during adaptive playback below. Hence why we load data
% here instead of within the loop below. 
t.datatype=2;

% Store time series in cell array (stim)
stim=cell(length(playback_list),1); % preallocate for speed.
for i=1:length(playback_list)
    [tstim, fsx]=SIN_loaddata(playback_list{i}, t);
    stim{i}=resample(tstim, FS, fsx); 
    
    % Playback channel check
    %   Confirm that the number of playback channels corresponds to the
    %   number of columns in stim{i}
    if numel(d.player.playback_channels) ~= size(stim{i},2)
        error(['Incorrect number of playback channels specified for file ' playback_list{i}]); 
    end % if numel(p.playback_channels) ...
    
end % for i=1:length(file_list)

clear tstim fsx;

% Add file_list to d structure
d.sandbox.playback_list=playback_list;

% Append playback files if flag is set
if d.player.append_files
    
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
end % 

% Open the playback device 
%   Only open audio device if 'continuous' selected. Otherwise, device
%   opening/closing is handled through portaudio_playrec.
%
%   We now use buffered playback for both continuous and bytrial
%   adaptive playback. So, open the handle if either is selected
if isequal(d.player.adaptive_mode, 'continuous') || isequal(d.player.adaptive_mode, 'bytrial')
    
    % Open the unmodulated device buffer
    phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels);
    
    % Open second handle for unmodulated sound playback
    if ~isempty(d.player.unmod_playback)        
        shand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels);
        uX = SIN_loaddata(d.player.unmod_playback); 
    end % if ~isempty(d.unmod_...
    
end % 

% Open a recording device if specified, specify as a recording device. 
if d.player.record_mic
    
    % Open recording device
    rhand = PsychPortAudio('Open', rstruct.DeviceIndex, 2, 0, FS, rstruct.NrInputChannels); 

    % Allocate Recording Buffer
    PsychPortAudio('GetAudioData', rhand, d.player.record.buffer_dur); 
    
    % Get rstatus - we might need this later to correct for differences in
    % predicted latency
    rstatus=PsychPortAudio('GetStatus', rhand);
    
end % if d.player.record_mic

%% PLAYBACK BUFFER INFORMATION
%   This information is only used in 'continuous' adaptive playback. Moved
%   here rather than below to minimize overhead (below this would be called
%   repeatedly, but these values do not change over stimuli). 
%
%   Use buffer information for 'bytrial' adaptive mode now as well. 
if isequal(d.player.adaptive_mode, 'continuous') || isequal(d.player.adaptive_mode, 'bytrial')
    % Create empty playback buffer
    buffer_nsamps=round(d.player.playback.block_dur*FS)*2; % need 2 x the buffer duration

    % block_nsamps
    %   This prooved useful in the indexing below. CWB opted to use a two block
    %   buffer for playback because it's the easiest to code and work with at
    %   the moment. 
    block_nsamps=buffer_nsamps/2; 

    % Find beginning of each "block" within the buffer
    block_start=[1 block_nsamps+1];
    
    % Start filling next block after first sample of this block has been
    % played
    refillat=ceil(1/block_nsamps);     
    
end % if isequal

% Create additional fields in 'sandbox'
%   Dummy values assigned as placeholders for intialization purposes. 
d.sandbox.trial=-1; % trial number
d.sandbox.nblock=-1; % nblock, the block number within the trial 
d.sandbox.block_num=-1; % block number we are in. 
d.sandbox.modifier_num=[];
d.sandbox.modcheck_num=1; % hard-coded for now since code only allows a single modcheck/trial (for now)

%% INITIALIZE MODCHECK and MODIFIER
%   These functions often have substantial overhead on their first call, so
%   they need to be primed (e.g., if a figure must be generated or a sound
%   device initialized).

% Call modcheck
[mod_code, d]=d.player.modcheck.fhandle(d);

% Initialized modifiers
%   Multiple modifiers possible
for modifier_num=1:length(d.player.modifier)
    
    % Update variable in sandbox
    d.sandbox.modifier_num=modifier_num;
    
    % Initialize modifier
    [~, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle([], mod_code, d); 
    
end % for modifier_num

for trial=1:length(stim)
    
    %% UPDATE TRIAL IN SANDBOX
    %   d.sandbox.trial is used by other functions
    d.sandbox.trial = trial; 
    
    %% EMPTY RECORDING
    rec=[]; 
    
    %% SELECT APPROPRIATE STIMULUS
    X=stim{trial};     
    
    %% FILL X TO MATCH NUMBER OF CHANNELS
    %   Create a matrix of zeros, then copy X over into the appropriate
    %   channels. CWB prefers this to leaving it up to psychportaudio to
    %   select the correct playback channels. 
    x=zeros(size(X,1), pstruct.NrOutputChannels);
    
    x(:, d.player.playback_channels)=X; % copy data over into playback channels
    X=x; % reassign X

    % Clear temporary variable x 
    clear x; 
       
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
            [Y, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle(X, mod_code, d); 
    
        end % for modifier_num                

    else
        % Assign X (raw data) to second variable for playback 
        Y=X; 
    end % isequal(d.player.adaptive_mode, 'bytrial')           
    
    % Switch to determine mode of adaptive playback. 
    switch lower(d.player.adaptive_mode)
        
        case {'continuous', 'bytrial'}             
            
            % Start recording device
            %   Just start during the first trial. This will be emptied
            %   after every trial. Should not need to restart the recording
            %   device. 
            if d.player.record_mic && trial ==1
                
                % Last input (1) tells PsychPortAudio to not move forward
                % until the recording device has started. 
                PsychPortAudio('Start', rhand, [], [], 1); 

                % rec_start_time is the (approximate) start time of the recording. This is
                % used to track the total recording time. 
                rec_start_time=GetSecs;
                
            end % if d.player.record_mic
            
            % SETUP unmod DEVICE
            %   - Fill the buffer
            %   - Wait for an appropriate lead time (see
            %   'unmod_leadtime'). 
            if ~isempty(d.player.unmod_playbackmode)
                switch d.player.unmod_playbackmode
                    case {'looped'}
    
                        % If this is looped playback, then start the playback of the
                        % masker sound and let it run forever and ever. 
                        if trial == 1
                            PsychPortAudio('FillBuffer', shand, uX');                                                                                 
                            PsychPortAudio('Start', shand, 0, [], 0);
                        end % if trial == 1
                        
                    case {'stopafter'}
                        
                        % Fill the buffer once
                        if trial ==1
                            PsychPortAudio('FillBuffer', shand, uX');
                        end % 
                        
                        % Infinite loop plaback
                        PsychPortAudio('Start', shand, 0, [], 0);
                        
                    otherwise
                        error('Unknown unmod_mode'); 
                end % switch/otherwise 
        
                % Crude wait time.                         
                WaitSecs(d.player.unmod_leadtime); 
                
                % Now wait 
                
            end % if ~isempty(d.player.unmod_playbackmode 
    
            %% CREATE WINDOWING FUNCTION (ramp on/off)
            %   This is used for continuous adaptive mode. The windowing function can
            %   be provided by the user, but it must be a function handle accepted
            %   by MATLAB's window function.    
            win=window(d.player.window_fhandle, round(d.player.window_dur*2*FS)); % Create onset/offset ramp

            % Match number of channels
            win=win*ones(1, size(X,2)); 
    
            % Create ramp_on (for fading in) and ramp_off (for fading out)
            ramp_on=win(1:ceil(length(win)/2),:); ramp_on=[ramp_on; ones(block_nsamps - size(ramp_on,1), size(ramp_on,2))];
            ramp_off=win(ceil(length(win)/2):end,:); ramp_off=[ramp_off; zeros(block_nsamps - size(ramp_off,1), size(ramp_off,2))];    
            
            % nblocks
            %   Variable only used by 'continuous' plaback
            nblocks=ceil(size(X,1)./size(ramp_on,1)); 
            
            % Store nblocks in sandbox. This is needed by some modcheck
            % functions for termination purposes (e.g.,
            % ANL_modcheck_keypress)
            d.sandbox.nblocks=nblocks; 
            
            % Loop through each section of the playback loop. 
            for block_num=1:nblocks
                tic
                % Store block number in sandbox - necessary for some
                % termination procedures
                d.sandbox.block_num = block_num; 
                
                % Which buffer block are we filling?
                %   Find start and end of the block
                startofblock=block_start(1+mod(block_num-1,2));
    
                % Find data we want to load 
                %   We load two blocks (the entire buffer length) for
                %   processing. Both blocks are modified below (if
                %   necessary) by the modifier(s). The first buffer block
                %   is loaded for playback and the second buffer block is
                %   saved for fading in/out on the next block_num
                %   iteration.
                if block_num>=nblocks-1
                    % Load with the remainder of X, then pad zeros.         
                    data=[Y(1+block_nsamps*(block_num-1):end, :); zeros(block_nsamps - size(Y(1+block_nsamps*(block_num-1):end, :),1), size(Y,2))];
                else
                    % Load a whole buffer worth of data. Used for fading
                    % in/out data below, although only 1/2 of buffer loaded
                    % at a time (block_nsamps).
                    data=Y(1+block_nsamps*(block_num-1):(block_nsamps)*block_num + block_nsamps,:);                    
                end 
                
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
                        [data, d]=d.player.modifier{d.sandbox.modifier_num}.fhandle(data, mod_code, d); 
                            
                    end % for modifier_num
                                        
                end % if isequal ...
       
                % Ramp new stream up, mix with old stream. 
                %   - The mixed signal is what's played back. 
                %   - We don't want to ramp the first block in, since the
                %   ramp is only intended to fade on block into the next in
                %   a clean way. 
                if block_num==1
                    data2play=data(1:block_nsamps, :);
                else
                    % Fade out previous setting (x) and fade in the new
                    % data (data). 
                    data2play=data(1:block_nsamps, :).*ramp_on + x.*ramp_off; 
                end % if block_num==1
                
                % Save second buffer block for fading on the next trial.
                %   Zero padding to make x play nicely when we're at the
                %   end of a sound                 
                x=[data(1+block_nsamps:end, :); zeros(block_nsamps-size(data(1+block_nsamps:end, :),1), size(data,2))]; 
                
                % Basic clipping check
                %   Kill any audio devices when this happens, then throw an
                %   error. 
                if max(max(abs(data))) > 1 && d.player.stop_if_error, 
                    PsychPortAudio('Close'); 
                    warning('Signal clipped!'); 
                    return % exit and return variables to the user. 
                end % if max(max(abs(data))) > 1
                    
                % First time through, we need to start playback
                %   This has to be done ahead of time since this defines
                %   the buffer size for the audio device. 
                if block_num==1
                   
                    % Start audio playback, but do not advance until the device has really
                    % started. Should help compensate for intialization time. 
        
                    % Fill buffer with zeros
                    PsychPortAudio('FillBuffer', phand, zeros(buffer_nsamps,size(data,2))');                     
                    
                    % Add one extra repetition for a clean transition.
                    % Note that below we wait for the second buffer block
                    % before we fill the first, so we end up losing a
                    % single playthrough the buffer. This could be handled
                    % better, but CWB isn't sure how to do that (robustly)
                    % at the moment.
                    PsychPortAudio('Start', phand, ceil( (nblocks)/2)+1, [], 0);                    
                    
                    % Wait until we are in the second block of the buffer,
                    % then start rewriting the first. Helps with smooth
                    % starts 
                    pstatus=PsychPortAudio('GetStatus', phand); 
                    while mod(pstatus.ElapsedOutSamples, buffer_nsamps) - block_start(2) < refillat % start updating sooner.  
                        pstatus=PsychPortAudio('GetStatus', phand); 
                    end % while
                    
                end % if block_num==1               
    
                % Load data into playback buffer
                %   CWB tried specifying the start location (last parameter), but he
                %   encountered countless buffer underrun errors. Replacing the start
                %   location with [] forces the data to be "appended" to the end of the
                %   buffer. For whatever reason, this is far more robust and CWB
                %   encountered 0 buffer underrun errors.                 
                PsychPortAudio('FillBuffer', phand, data2play', 1, []);  
                                
                pstatus=PsychPortAudio('GetStatus', phand);
                
                toc
                
                % Now, loop until we're half way through the samples in 
                % this particular buffer block.
                while mod(pstatus.ElapsedOutSamples, buffer_nsamps) - startofblock < refillat ... 
                        && block_num<nblocks % additional check here, we don't need to be as careful for the last block
                    pstatus=PsychPortAudio('GetStatus', phand); 
                end % while
                
                % Error checking after each loop
                if d.player.stop_if_error && (pstatus.XRuns >0 || pstatus.TimeFailed >0)
                    PsychPortAudio('Stop', phand); 
                    error('Error during sound playback. Check buffer_dur.'); 
                end % if d.player.stop ....
                
                % Zero out the second buffer block if we happen to end in
                % the first. 
                %   If this is not done, whatever was left in the second
                %   buffer block is played back again, which creates an
                %   artifact. 
                if block_num==nblocks && startofblock==block_start(1)
                    data=zeros(block_nsamps, size(X,2)); 
                    PsychPortAudio('FillBuffer', phand, data', 1, []);  
                end % if block_num==nblocks
                
                % Empty recording buffer frequently
                if d.player.record_mic
                    
                    % Check to make sure we are checking our buffer faster
                    % enough
                    if GetSecs - rec_start_time > d.player.record.buffer_dur
                        error('Recording buffer too short'); 
                    end 
                    
                    % Empty recording buffer, if necessary. 
                    rec=[rec; PsychPortAudio('GetAudioData', rhand)']; 
                    
                    % Reset recording time
                    rec_start_time=GetSecs; 
                    
                end % d.player.record_mic
                
            end % for block_num=1:nblocks
            
            % Schedule stop of playback device.
            %   Should wait for scheduled sound to complete playback. 
            PsychPortAudio('Stop', phand, 1); 
            
            % Stop unmodulated noise
            if isequal(d.player.unmod_playbackmode, 'stopafter')
                WaitSecs(d.player.unmod_lagtime);
                PsychPortAudio('Stop', shand, 0); 
            end % 
            
            % Run the modcheck.
            if isequal(d.player.adaptive_mode, 'bytrial')
                
                % Call modcheck     
                [mod_code, d]=d.player.modcheck.fhandle(d);
                
                % Check to make sure we are checking our buffer faster
                % enough
                if GetSecs - rec_start_time > d.player.record.buffer_dur
                    error('Recording buffer too short'); 
                end % if GetSecs ...
                
                % Empty recording buffer, if necessary. 
                rec=[rec; PsychPortAudio('GetAudioData', rhand)'];  
                
            elseif isequal(d.player.adaptive_mode, 'continuous')
                
                % Go ahead and empty the buffer again. 
                rec=[rec; PsychPortAudio('GetAudioData', rhand)'];                  
                
            end % if isequal( ...

            % Save recording to sandbox
            d.sandbox.voice_recording{trial} = rec; 
            clear rec; % just to be safe, clear the variable
            
        otherwise
            
            error(['Unknown adaptive mode (' d.player.adaptive_mode '). See ''''adaptive_mode''''.']); 
            
    end % switch d.player.adaptive_mode

end % for trial=1:length(X)

% Close all open audio devices
PsychPortAudio('Close')

% Attach end time
d.sandbox.end_time=now; 

% Attach (modified) structure to results
%   This is returned to the user. 
results.RunTime = d; 