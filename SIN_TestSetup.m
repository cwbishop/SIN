function opts=SIN_TestSetup(testID)
%% DESCRIPTION:
%
%   Function to return test information. This will vary based on the test.
%   Alternatively, this can also return a list of available tests
%   (default).
%
% INPUT:
%
%   testID:     string, test identifer. Or, if the user wants to return a
%               list of available tests, leave testID empty.
%
% OUTPUT:
%
%   opts:       a test setup structure. Or, if testID is empty, a cell
%               array of available tests.
%
% Development:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   5/14

if ~exist('testID', 'var') || isempty(testID), testID='testlist'; end 

switch testID;
    
    case 'testlist'
        
        % Get cases within switch. Each case might be a test.
        %   Some of the cases are callback specific (e.g., generating the
        %   test list, an empty options structure, etc.). These are
        %   excluded based on the exclusion list (exlist) below. 
        opts = getCases(); 
        
        % Exclusion list
        %   Remove callback helpers (like 'empty', 'Project AD', etc);
        exlist={'Defaults' 'testlist'}; 
        
        % Assume we include everything by default
        mask=true(size(opts)); 
        
        for c=1:length(opts)
            if ~isempty(find(ismember(exlist, opts{c}), 1, 'first'))
                mask(c)=false;
            end
        end % for c
        
        % Return test names        
        opts={opts{mask}}; 
        
    case 'Defaults'
                
        % Create an empty SIN testing structure
        opts = struct( ...
            'general', struct(), ... % general information
            'specific', struct(), ... % test specific parameters (used by auxiliary functions like modchecks/modifiers/GUIs
            'player', struct(), ... % player configuration structure (e.g., for portaudio_adaptiveplay)
            'sandbox', struct());  % scratch pad for passing saved variables between different functions (e.g., data to plot, figure handles, etc.)
        
        % Root SIN directory
        opts.general.root = fileparts(which('SIN_TestSetup.m'));  
        
        % Subject directory
        opts.general.subjectDir = fullfile(opts.general.root, 'subject_data'); 
        
        % Calibration information
        opts.general.calibrationDir = fullfile(opts.general.root, 'calibration');
        opts.general.calibration_regexp = '.mat$'; % 
        
        % subject ID motif. Described using regexp. Used in
        % SIN_register_subject.m
        opts.general.subjectID_regexp='^[1 2][0-9]{3}$';
        
        % List of available tests
        %   This will vary by project. Field used to generate test list in
        %   SIN_GUI. CWB does not recall using it elsewhere. 
        opts.general.testlist = SIN_TestSetup('testlist'); 
        
        % Set sound output paramters. 
        opts.player.playback = struct( ...
            'device', portaudio_GetDevice(8), ... % device structure
            'block_dur', 0.08, ... % 80 ms block duration.
            'fs', 44100); % sampling rate            
        
        % Recording device
        opts.player.record = struct( ...
            'device', portaudio_GetDevice(1), ... % device structure. Use the MME recording device. Windows Sound introduces a lot of crackle in recording.
            'buffer_dur', 120, ... recording buffer duration. Make this longer than you'll ever need for a single trial of HINT
            'fs', 44100); % recording sampling rate
        
        % Stop playback if we encounter an error
        opts.player.stop_if_error = true; 
        
        % Add player control modifiers
        %   Include a basic playback controller to handle "pauses",
        %   "resume", and "quit" requests.
        opts.player.modifier{1} = struct( ...
            'fhandle', @modifier_PlaybackControl); 
            
    case 'HINT (SNR-50)'
        
        % ============================
        % Get default information
        % ============================
        opts=SIN_TestSetup('Defaults'); 
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID='HINT (SNR-50)';
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'HINT');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp='List[0-9]{2}'; 
                
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
        opts.specific.hint_lookup=struct(...
            'filename', fullfile(opts.specific.root, 'HINT.xlsx'), ...
            'sheetnum', 2); 
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @portaudio_adaptiveplay; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'bytrial', ... % 'bytrial' means modchecks performed after each trial.
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'randomize',        true, ...   % randomize trial order before playback
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'playback_channels',[1 2], ...  % channels to present sounds to. 
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'startplaybackat',    0, ...  % start playback at beginning of files
            'state',    'run', ... % start in run state
            'unmod_playbackmode', 'stopafter', ... % stop unmodulated noise playback after each trial
            'unmod_channels',   [1 2], ...
            'unmod_leadtime',   1, ... % start unmodulated sound 1 sec before sentence onset
            'unmod_lagtime',    1, ... % continue noise 1 sec after sentence ends
            'unmod_playback',   {{fullfile(opts.specific.root, 'HINT-Noise.wav')}}); % noise file
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',         @HINT_modcheck_GUI, ...
            'scoring_method',  'sentence_based', ... % score whole sentence (as traditionally done)
            'score_labels',   {{'Correct', 'Incorrect'}}); % scoring labels for GUI
        
        % ============================
        % Modifier configuration        
        %   We use two modifiers, but CWB can't recall why. Need to check
        %   this. 
        % ============================
        opts.player.modifier{end+1}=struct( ...
            'fhandle',  @modifier_dBscale, ... % use a decibel scale
            'dBstep',   [4 2], ...  % decibel step size (4 dB, then 2 dB)
            'change_step', [1 5], ...   % trial on which to change the step size
            'channels', 2);  % apply modification to channel 2            
    case 'ANL'
        % ANL is actually a sequence of tests. The list includes the
        % following:
        %
        %   1. ANL (MCL-Too Loud)
        %   2. ANL (MCL-Too Quiet)
        %   3. ANL (MCL-Estimate)
        %   4. ANL (BNL-Too Loud)
        %   5. ANL (BNL-Too Quiet)
        %   6. ANL (BNL-Estimate)
        %
        % These parameters serve as the base settings and tests to run, but
        % additional steps must be taken to copy parameters over from one
        % test sequence to the next (e.g., the buffer position and overall
        % sound levels, according to modifier_dBscale). Also need to copy
        % over calibration information from one test to the next.        
        opts(1)=SIN_TestSetup('ANL (MCL-Too Loud)'); 
        opts(2)=SIN_TestSetup('ANL (MCL-Too Quiet)'); 
        opts(3)=SIN_TestSetup('ANL (MCL-Estimate)'); 
        
    case 'ANL (MCL-Too Loud)'
        % ANL (MCL-Too Loud) is the first step in the ANL sequence. The
        % listener is instructed to adjust the speech track until it is too
        % loud. 
        
        % Get base
        opts=SIN_TestSetup('ANL (base)'); 
        
        % Change testID
        opts.specific.testID='ANL (MCL-Too Loud)';
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'You will listen to a story through the loudspeaker. These hand held buttons will allow you to make adjustments (Show the subject the buttons). When you want to turn the volume up - push this button (point to the up button), and when you want to turn the volume down - push this button (point to the down button). I will instruct you throughout the experiment.'};
        
    case 'ANL (MCL-Too Quiet)'
        
        % This is just like the ANL (base), but with different
        % instructions and a different starting buffer position.
        opts=SIN_TestSetup('ANL (base)'); 
        
        % Change testID
        opts.specific.testID='ANL (MCL-Too Quiet)'; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Using the down button, turn the level of the story down until it is too soft (i.e., softer than most comfortable). Each time you push the down button, I will turn the story down (use 5 dB steps)'};
        
    case 'ANL (MCL-Estimate)' 
        
        opts=SIN_TestSetup('ANL (base)'); 
        
        % Change testID
        opts.specific.testID='ANL (MCL-Estimate)'; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Now turn the level of the story back up to until the story is at your most comfortable listening level (i.e., or your prefect listening level) (use 2 dB steps).'};           
        
    case 'ANL (base)' % base settings for sequence of tests comprising ANL
        % ANL is administered differently than HINT or PPT. Here's a
        % very basic breakdown of the procedure.
        %
        %   Stage 1: Establishing the most comfortable level (MCL)
        %
        %       1. Start story at 30 dB HL. 
        %       2. Subject adjusts speech until it is uncomfortable (5
        %       dB steps)
        %       3. Subject adjust speech until it is too quiet (5 dB
        %       steps)
        %       4. Turn story back up until it is at "[the subject's] most
        %       comfortable listeneing level". (2 dB steps)
        %           - Note: OK to decrease too, if necessary. 
        %       5. Record the speech level. This is MCL 
        %
        %   Stage 2: Establishing the background noise level (BNL)
        %
        %       1. Add in background noise (30 dB HL). 
        %       2. Listener raises noise level until he/she can no
        %       longer hear the story (5 dB steps)
        %       3. Listener lowers the noise level until he/she can
        %       understand the story easily. (5 dB steps)
        %       4. Listener adjusts background noise to the MOST noise
        %       that he would be willing to tolerate and still follow
        %       the story for a long period of time without becoming
        %       tense or tired. 
        %       5. Record noise level. This is BNL. 
        %
        %   Stage 3: Acceptable Noise Level (ANL) Calculation
        %
        %       1. MCL (stage 1) - BNL;
         
        % Test setup for the Acceptable Noise Level (ANL) Test
        % ============================
        % Get default information
        % ============================
        opts=SIN_TestSetup('Defaults');
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID='ANL';
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'ANL');
              
        % Regular expression used to grab available list of ANL files
        %   Traditionally, there's only one file with a male talker in one
        %   channel and a multi-talker stream in a second channel. These
        %   are controlled independently, but often routed to the same
        %   speaker. 
        %   
        %   This field is used in SIN_stiminfo.m. 
        opts.specific.anl_regexp='ANL.wav'; 
        % ============================
        % Playback configuration
        %
        %   CWB running into issues with playback buffer size. Needs to be
        %   longer for longer files (due to indexing overhead)
        %
        % ============================
%         opts.player.playback.block_dur=0.3; 
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @portaudio_adaptiveplay; 
        
        warning('Mixing weights are set to 0.5. Need to make sure this is what CWB wants'); 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'continuous', ... % 'continuous' adaptive playback
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'randomize',        false, ...   % randomize trial order before playback
            'append_files',     true, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'looped', ... % loop sound playback - so the same sound just keeps playing over and over again until the player exits
            'startplaybackat',    0, ...  % start playback at beginning of sound 
            'channel_mixer',    {{[0.5; 0.5] [0; 0]}}, ... % Play both channels to left ear only. 
            'state',    'pause', ... % start in paused state
            'unmod_playbackmode', [], ... % no unmodulated sound
            'unmod_channels',   [], ... % no unmodulated sound
            'unmod_leadtime',   [], ... % no unmodulated sound
            'unmod_lagtime',    [], ... % no unmodulated sound
            'unmod_playback',   {{}});  % no unmodulated sound
        
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',  @ANL_modcheck_keypress, ...     % check for specific key presses
            'instructions', {{'You will listen to a story through the loudspeaker. These hand held buttons will allow you to make adjustments (Show the subject the buttons). When you want to turn the volume up - push this button (point to the up button), and when you want to turn the volume down - push this button (point to the down button). I will instruct you throughout the experiment.'}}, ...
            'keys',     [KbName('i') KbName('j') KbName('p') KbName('q') KbName('r')], ...  % first key makes sounds louder, second makes sounds quieter, third for pause, fourth for quit, fifth for run             
            'map',      zeros(256,1));
%             'fhandle', @modcheck_ANLGUI, ...
            
        % Assign keys in map
        opts.player.modcheck.map(opts.player.modcheck.keys)=1; 
        
        % ============================
        % Modifier configuration        
        %   We use two modifiers, but CWB can't recall why. Need to check
        %   this. 
        % ============================
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_dBscale, ... % use a decibel scale
            'dBstep',   5, ...  % use constant 1 dB steps
            'change_step', 1, ...   % always 1 dB
            'channels', 1);  % apply modification to channel 2            
            
    otherwise
        
        error('unknown testID')
        
end % switch 

