function d=portaudio_adaptiveplay(X, varargin)
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
%                           'realtime': apply modifications in as close to
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
%                           'byfile':      apply modifications at the end 
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
%                       applies to 'realtime' adaptive playback. 
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
% Windowing options (for 'realtime' playback only):
%
%   In 'realtime' mode, data are frequently ramped off or on (that is, fade
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
%   11. Change 'realtime' to 'ongoing'. Although close, 'realtime' is a
%   misnomer. 
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
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% FUNCTION SPECIFIC DEFAULTS
%   - Use a Hanning windowing function by default
%   - Use 5 ms ramp time
%   - Do not append files by default 
%   - Abort if we encounter issues with the sound playback buffer. 
if ~isfield(d, 'window_fhandle') || isempty(d.window_fhandle), d.window_fhandle=@hann; end
if ~isfield(d, 'window_dur') || isempty(d.window_dur), d.window_dur=0.005; end 
if ~isfield(d, 'append_files') || isempty(d.append_files), d.append_files=false; end 
if ~isfield(d, 'stop_if_error') || isempty(d.stop_if_error), d.stop_if_error=true; end 

% unmod device defaults
if ~isfield(d, 'unmod_leadtime') || isempty(d.unmod_leadtime), d.unmod_leadtime=0; end 
if ~isfield(d, 'unmod_playback'), d.unmod_playback={}; end % no unmod playback file by default
if ~isfield(d, 'unmod_playbackmode') || isempty(d.unmod_playbackmode), d.unmod_playbackmode=''; end 
if ~isempty(d.unmod_playback) && (~isfield(d, 'unmod_channels') || isempty(d.unmod_channels)), d.unmod_channels=d.playback_channels; end     
% Save file names
playback_list=X; 
clear X; 

% Set sampling rate
FS=d.fs; 

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
    if numel(d.playback_channels) ~= size(stim{i},2)
        error(['Incorrect number of playback channels specified for file ' playback_list{i}]); 
    end % if numel(p.playback_channels) ...
    
end % for i=1:length(file_list)

clear tstim fsx;

% Add file_list to d structure
d.playback_list=playback_list;

% Append playback files if flag is set
if d.append_files
    
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
    [pstruct]=portaudio_GetDevice(d.playback.device);
catch
    InitializePsychSound; 
    [pstruct]=portaudio_GetDevice(d.playback.device);
end % 

% Open the playback device 
%   Only open audio device if 'realtime' selected. Otherwise, device
%   opening/closing is handled through portaudio_playrec.
%
%   We now use buffered playback for both realtime and byfile
%   adaptive playback. So, open the handle if either is selected
if isequal(d.adaptive_mode, 'realtime') || isequal(d.adaptive_mode, 'byfile')
    
    % Open the unmodulated device buffer
    phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels);
    
    % Open second handle for unmodulated sound playback
    if ~isempty(d.unmod_playback)        
        shand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, FS, pstruct.NrOutputChannels);
        uX = SIN_loaddata(d.unmod_playback); 
    end % if ~isempty(d.unmod_...
    
end % 

%% BUFFER INFORMATION
%   This information is only used in 'realtime' adaptive playback. Moved
%   here rather than below to minimize overhead (below this would be called
%   repeatedly, but these values do not change over stimuli). 
%
%   Use buffer information for 'byfile' adaptive mode now as well. 
if isequal(d.adaptive_mode, 'realtime') || isequal(d.adaptive_mode, 'byfile')
    % Create empty playback buffer
    buffer_nsamps=round(d.block_dur*FS)*2; % need 2 x the buffer duration

    % block_nsamps
    %   This prooved useful in the indexing below. CWB opted to use a two block
    %   buffer for playback because it's the easiest to code and work with at
    %   the moment. 
    block_nsamps=buffer_nsamps/2; 

    % Find beginning of each "block" within the buffer
    block_start=[1 block_nsamps+1];
    
    % Refill at at the 1/4 of the way through a buffer block
    refillat=block_nsamps/4; 
    
end % if isequal

% Create global trial variable. This information is often needed for
% modification check and modifier functions. So, just make it available
% globally and let them tap it if necessary. 
global trial;

% Create a global variable for tracking which modifier we are assessing.
% This may be needed by modification functions to store data in the correct
% fields. 
global modifier_num;

%% INITIALIZE MODCHECK and MODIFIER
%   These functions often have substantial overhead on their first call, so
%   they need to be primed (e.g., if a figure must be generated or a sound
%   device initialized).

% Call modcheck
[mod_code, d]=d.modcheck.fhandle(d);      

% Initialized modifiers
%   Multiple modifiers possible
for modifier_num=1:length(d.modifier)
    [~, d]=d.modifier{modifier_num}.fhandle([], mod_code, d); 
end % for modifier_num

for trial=1:length(stim)
    
    %% SELECT APPROPRIATE STIMULUS
    X=stim{trial}; 
    
    %% FILL X TO MATCH NUMBER OF CHANNELS
    %   Create a matrix of zeros, then copy X over into the appropriate
    %   channels. CWB prefers this to leaving it up to psychportaudio to
    %   select the correct playback channels. 
    x=zeros(size(X,1), pstruct.NrOutputChannels);
    
    x(:, d.playback_channels)=X; % copy data over into playback channels
    X=x; % reassign X

    % Clear temporary variable x 
    clear x; 
                        
    % Switch to determine mode of adaptive playback. 
    switch lower(d.adaptive_mode)
        
        case {'realtime', 'byfile'} 
            
            % SETUP unmod DEVICE
            %   - Fill the buffer
            %   - Wait for an appropriate lead time (see
            %   'unmod_leadtime'). 
            if ~isempty(d.unmod_playbackmode)
                switch d.unmod_playbackmode
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
                WaitSecs(d.unmod_leadtime); 
                
                % Now wait 
                
            end % if ~isempty(d.unmod_playbackmode 
    
            %% CREATE WINDOWING FUNCTION (ramp on/off)
            %   This is used for realtime adaptive mode. The windowing function can
            %   be provided by the user, but it must be a function handle accepted
            %   by MATLAB's window function.    
            win=window(d.window_fhandle, round(d.window_dur*2*FS)); % Create onset/offset ramp

            % Match number of channels
            win=win*ones(1, size(X,2)); 
    
            % Create ramp_on (for fading in) and ramp_off (for fading out)
            ramp_on=win(1:ceil(length(win)/2),:); ramp_on=[ramp_on; ones(block_nsamps - size(ramp_on,1), size(ramp_on,2))];
            ramp_off=win(ceil(length(win)/2):end,:); ramp_off=[ramp_off; zeros(block_nsamps - size(ramp_off,1), size(ramp_off,2))];    
            
            % nblocks
            %   Variable only used by 'realtime' plaback
            nblocks=ceil(size(X,1)./size(ramp_on,1)); 
            
            % Loop through each section of the playback loop. 
            for i=1:nblocks
%                 tic
                % Which buffer block are we filling?
                %   Find start and end of the block
                startofblock=block_start(1+mod(i-1,2));
    
                % Find data we want to load 
                if i==nblocks
                    % Load with the remainder of X, then pad zeros.         
                    data=[X(1+block_nsamps*(i-1):end, :); zeros(block_nsamps - size(X(1+block_nsamps*(i-1):end, :),1), size(X,2))];
                else
                    data=X(1+block_nsamps*(i-1):(block_nsamps)*i,:);
                end 
                
                % Save upcoming data
                x=data.*ramp_off;
                
                % Modcheck and modifier for realtime playback
                if isequal(d.adaptive_mode, 'realtime')
                    
                    % Check if modification necessary
                    [mod_code, d]=d.modcheck.fhandle(d); 
                    
                    % Modify main data stream
                    %   Apply all modifiers. 
                    for modifier_num=1:length(d.modifier)
                        [X, d]=d.modifier{modifier_num}.fhandle(X, mod_code, d); 
                    end % for modifier_num ...
                    
                end % if isequal ...
        
                % Grab data from modified signal
                if i==nblocks
                    % Load with the remainder of X, then pad zeros.         
                    data=[X(1+block_nsamps*(i-1):end, :); zeros(block_nsamps - size(X(1+block_nsamps*(i-1):end, :),1), size(X,2))];
                else
                    data=X(1+block_nsamps*(i-1):(block_nsamps)*i,:);
                end % if 
        
                % Ramp new stream up, mix with old stream. 
                %   - The mixed signal is what's played back. 
                %   - We don't want to ramp the first block in, since the
                %   ramp is only intended to fade on block into the next in
                %   a clean way. 
                if i==1
                    data=data + x;
                else
                    data=data.*ramp_on + x; 
                end % if i==1
    
                % Basic clipping check
                %   Kill any audio devices when this happens, then throw an
                %   error. 
                if max(max(abs(data))) > 1, 
                    PsychPortAudio('Close'); 
                    error('Signal clipped!'); 
                end % if max(max(abs(data))) > 1
                    
                % First time through, we need to start playback
                %   This has to be done ahead of time since this defines
                %   the buffer size for the audio device. 
                if i==1
                   
                    % Start audio playback, but do not advance until the device has really
                    % started. Should help compensate for intialization time. 
        
                    % Fill buffer with zeros
                    PsychPortAudio('FillBuffer', phand, zeros(buffer_nsamps,size(data,2))');                     
                    
                    % Add one extra repetition to for a clean transition.
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
                    
                end % if i==1               
    
                % Load data into playback buffer
                %   CWB tried specifying the start location (last parameter), but he
                %   encountered countless buffer underrun errors. Replacing the start
                %   location with [] forces the data to be "appended" to the end of the
                %   buffer. For whatever reason, this is far more robust and CWB
                %   encountered 0 buffer underrun errors.                 
                PsychPortAudio('FillBuffer', phand, data', 1, []);  
                                
%                 toc

                pstatus=PsychPortAudio('GetStatus', phand);
                
                % Now, loop until we're half way through the samples in 
                % this particular buffer block.
                while mod(pstatus.ElapsedOutSamples, buffer_nsamps) - startofblock < refillat ... 
                        && i<nblocks % additional check here, we don't need to be as careful for the last block
                    pstatus=PsychPortAudio('GetStatus', phand); 
                end % while
                
                % Error checking after each loop
                if d.stop_if_error && (pstatus.XRuns >0 || pstatus.TimeFailed >0)
                    PsychPortAudio('Stop', phand); 
                    error('Error during sound playback. Check buffer_dur.'); 
                end % if d.stop ....
                
                % Zero out the second buffer block if we happen to end in
                % the first. 
                %   If this is not done, whatever was left in the second
                %   buffer block is played back again, which creates an
                %   artifact. 
                if i==nblocks && startofblock==block_start(1)
                    data=zeros(block_nsamps, size(X,2)); 
                    PsychPortAudio('FillBuffer', phand, data', 1, []);  
                end % if i==nblocks
                
            end % for i=1:nblocks
            
            % Schedule stop of playback device.
            %   Should wait for scheduled sound to complete playback. 
            PsychPortAudio('Stop', phand, 1); 
            
            % Stop unmodulated noise
            if isequal(d.unmod_playbackmode, 'stopafter')
                WaitSecs(d.unmod_lagtime);
                PsychPortAudio('Stop', shand, 0); 
            end % 
            
            % By file modcheck and data modification. 
            if isequal(d.adaptive_mode, 'byfile')
                
                for modifier_num=1:length(d.modifier)
                    [X, d]=d.modifier{modifier_num}.fhandle(X, mod_code, d);
                end % for modifier_num                
                
                % Call modcheck        
                [mod_code, d]=d.modcheck.fhandle(d); 

            end % isequal(d.adaptive_mode, 'byfile')           

        otherwise
            
            error(['Unknown adaptive mode (' d.adaptive_mode '). See ''''adaptive_mode''''.']); 
            
    end % switch d.adaptive_mode

end % for trial=1:length(X)

% Close all open audio devices
PsychPortAudio('Close')

% Save data structure and other information
%   XXX Under development XXX