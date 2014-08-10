function opts=SIN_TestSetup(testID, subjectID)
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
%   1. Create case to return test list for GUI. 
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
        tests = getCases(); 
        
        % Only list the following as fully function "tests". The cases that
        % are not listed are typically building blocks for these
        % higher-level calls. These are the tests that are typically listed
        % in the GUI. Other tests are meant only for "Advanced" users (not
        % students), so we won't list them at all. 
        %
        %   CWB changed this to an exclusion list instead. 
        tests2list={'Defaults' 'testlist'};
        
        % Assume we include everything by default
        mask=true(size(tests)); 
        
        for c=1:length(tests)
            if ~isempty(find(ismember(tests2list, tests{c}), 1, 'first'))
                mask(c)=false;
            end
        end % for c
                
        % Return test names 
        %   List tests vertically (easier to skim through)
        opts={tests{mask}}'; 
        
        % Return here so we don't try to assign a UUID.        
        return
        
    case 'Defaults'
               
        % Create an empty SIN testing structure
        opts = struct( ...
            'subject', struct(), ... % subject specific information, like subject ID, etc. 
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
        
        % Set subject information
        %   - Set subject identifier (subjectID)
        %   - Set subject-specific directory. This is different from the
        %   subjectDir found in the general field. 
        opts.subject.subjectID = subjectID; 
        opts.subject.subjectDir = fullfile(opts.general.subjectDir, opts.subject.subjectID); 
        
        % Set sound output paramters. 
        opts.player.playback = struct( ...
            'device', portaudio_GetDevice(9), ... % device structure
            'block_dur', .5, ... % 200 ms block duration.
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
            'fhandle', @modifier_PlaybackControl, ...
            'mod_stage',    'premix');             
        
        % Where the UsedList is stored. 
        opts.specific.genPlaylist.UsedList = fullfile(opts.subject.subjectDir, [opts.subject.subjectID '-UsedList.mat']); % This is where used list information is stored.
        
        % Return so we do not assign a UUID to defaults. 
        return
        
%     case 'Calibrate'
%         
%         % ============================
%         % Get default information
%         % ============================
%         opts=SIN_TestSetup('Defaults', subjectID); 
%         
%         % ============================
%         % Test specific information. These arguments are used by
%         % test-specific auxiliary functions. Most of this information is
%         % used by SIN_calibrate. 
%         % ============================
%         opts.specific=struct( ...
%             'testID',   'Calibrate', ... % testID
%             'root',     opts.general.calibrationDir, ...
%             'output_root',  fullfile(opts.general.calibrationDir, date, date), ... % create a directory for today's calibration
%             'cal_regexp',   [], ...
%             'reference', struct(...
%                 'absoluteSPL', 114), ...
%             'makeFilter', struct(...                
%                 'fhandle',  @SIN_makeFilter, ... % use SIN_makeFilter to do computations
%                 'fs',   opts.player.record.fs, ... % sampling rate set to recording rate
%                 'plev', 1,  ... % generate summary plots by default
%                 'window',   1,  ... % 1 sec window for spectral estimation
%                 'noverlap', [], ... % use default for overlap
%                 'nfft', opts.player.record.fs,  ... % number of fft bins
%                 'filter_order', 500,    ... % FIR filter order.
%                 'smoothPSD',    false,  ... % don't smooth PSD by default. This is loosely controlled by filter order anyway
%                 'KernelSize',   []), ... % this won't be used if smoothPSD==false, so leave it empty
%             'instructions', struct(...
%                 'noise_estimation', 'Get down. Shut up', ...
%                 'reference', 'attach the device', ...
%                 'playback',     'unattach the device and sit down'), ...
%             'physical_channels',    [1 2], ... % physical channels to calibrate. These are the channels you'll be playing sounds back from during your experiment.
%             'data_channels',    1, ... % just one channel for white noise stimulus. 
%             'calstimDir',   fullfile(opts.general.root, 'playback', 'calibration'), ... % we'll use the ANL babble masker as the calibration stimulus
%             'calstim_regexp', 'whitenoise_10sec_sc.wav', ... % 10 sec white noise stimulus
%             'remove_noise_floor',   false, ... % do not attempt to remove power estimate of noise floor 
%             'validate', true,   ... % validate filters after estimation.
%             'record_channels',  1); % just use channel 1 from stereo recording on my device.       
%             
%             
%         % ============================
%         % Player configuration
%         %   The fields below are used by the designated player to configure
%         %   playback.
%         %
%         %   - Note: some of these are set in 'Project AD' above
%         % ============================
%         opts.player = varargin2struct( ...
%             opts.player, ...
%             'player_handle', @portaudio_adaptiveplay, ...
%             'adaptive_mode',    'continuous', ... % 'continuous' adaptive playback
%             'record_mic',       true, ...   % record playback and vocal responses via recording device. 
%             'randomize',        false, ...   % randomize trial order before playback
%             'append_files',     false, ...  % append files before playback (makes one long trial)
%             'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
%             'window_dur',       0.005, ...  % window duration in seconds.
%             'playback_mode',    'standard', ... % just play sound once
%             'startplaybackat',    0, ...  % start playback at beginning of sound 
%             'mod_mixer',    [], ... % leave empty, this will be generated in SIN_calibrate.m. See specific.physical_channels and specific.data_channels
%             'state',    'pause'); % start in paused state     
%         
%         % ============================
%         % Modification check (modcheck) configuration  
%         %   - Use the ANLGUI for test administration. It's basically what
%         %   we need anyway, but we'll need to hide the volume adjustment
%         %   keys. 
%         % ============================
%         opts.player.modcheck=struct(...
%             'fhandle',  @ANL_modcheck_keypress, ...     % check for specific key presses
%             'instructions', {{'You will listen to a story through the loudspeaker. These hand held buttons will allow you to make adjustments (Show the subject the buttons). When you want to turn the volume up - push this button (point to the up button), and when you want to turn the volume down - push this button (point to the down button). I will instruct you throughout the experiment.'}}, ...
%             'keys',     [KbName('i') KbName('j') KbName('p') KbName('q') KbName('r')], ...  % first key makes sounds louder, second makes sounds quieter, third for pause, fourth for quit, fifth for run             
%             'map',      zeros(256,1), ...
%             'title',    'Calibration: ');
%             
%         % Assign keys in map
%         %   Only listen for the quit/begin keys (no pausing or intensity
%         %   adjustments allowed) 
%         opts.player.modcheck.map(opts.player.modcheck.keys(4:end))=1; 
%         
%         % ============================
%         % Modifier configuration                
%         % ============================
%         
%         % Modifier to apply inline filtering
%         %   Leave this empty for now until the calibration code is
%         %   well-vetted. 
%         
%         
%         % Modifier to track mod_mixer settings. 
%         %   This isn't strickly necessary, but CWB wants it here as an
%         %   additional sanity check to make sure the mixer is not changing
%         %   over the course of the experiment. Using the ANLGUI is
%         %   convenient, but can be scary if something unexpected happens
%         %   (like the experimenter or listener accidentally presses keys
%         %   that adjust playback volume). This possibility should be very
%         %   small since the map above is modified to ignore the increase
%         %   and decrease volume key presses, but CWB is still paranoid. 
%         opts.player.modifier{end+1} = struct( ...
%             'fhandle',  @modifier_trackMixer, ...
%             'mod_stage',    'premix');   % track prior to mixing
      
    case 'PPT'
        
        % Perceived Performance Test (PPT) is a subjective measure of
        % performance on a HINT-style test. This should be otherwise
        % identical to HINT (SNR-50, Sentence-Based) algorithm.
        opts = SIN_TestSetup('HINT (SNR-50, Sentence-Based)');
        
        % Change the test ID to PPT so the correct scoring scheme is used.
        opts.specific.testID = testID; 
        
        % Change scoring method to PPT based scoring
        opts.player.modcheck.scored_items = 'sentences';
        
        % Change scoring labels to something more intuitive
%         opts.player.modcheck.score_labels = {'C', 'Not_All'};

    case 'HINT (SNR-80, NALadaptive)'
        
        % Use the 'HINT (SNR-50, NALadaptive)' as a starting point
        opts = SIN_TestSetup('HINT (SNR-50, NALadaptive)');
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change target percentage to 80% (instead of 50%)
        opts.player.modcheck.algoParams.target = 80; 
        
    case 'HINT (SNR-50, NALadaptive)'
        
        % Administer HINT using NALadaptive algorithm.
        
        % Use the HINT as traditionally scored as a starting point
        opts = SIN_TestSetup('HINT (SNR-50, Sentence-Based)', subjectID);
        
        % Change testID
        opts.specific.testID = testID;
        
        % Find the scaling modifier
        mask = getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_dBscale_mixer); 
        
        % Make sure we have one and only one matching modifier
        if numel(mask) ~= 1
            error('Found too many (or too few) matching modifiers');
        end % if numel(mask) ~= 1
        
        % Change function handle
        opts.player.modifier{mask}.fhandle = @modifier_NALscale_mixer;
        
        % Clear out the fields we don't need. 
        opts.player.modifier{mask} = rmfield(opts.player.modifier{mask}, {'dBstep', 'change_step'}); 
        
        % Change algorithm used by modcheck
        opts.player.modcheck.algo = 'NALadaptive';
        
        % Add additional parameters for NAL algorithm
        opts.player.modcheck.algoParams = struct( ...
            'target',   50, ... % target SNR-50
            'correction_factor',    2, ... % use correction factor of 2 for SEM calculations. Default in paper
            'min_trials',   20);    % # of trials (minimum) in phase 2/3. Since using the HINT stimuli, use multiples of 10           
        
    case 'HINT (SNR-50, Sentence-Based)'
        
        % ============================
        % Get default information
        % ============================
        opts=SIN_TestSetup('Defaults', subjectID); 
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID = testID;
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'HINT');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp='List[0-9]{2}'; 
                
        % Set regular expression for wav files
        opts.specific.wav_regexp = '+noise.wav$'; % use files with noise in channel 1. 
        
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
        opts.specific.hint_lookup=struct(...
            'filename', fullfile(opts.specific.root, 'HINT.xlsx'), ...
            'sheetnum', 2); 
        
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 2; % The number of lists to include in the playlist. Most lists have a fixed number of stimuli, so multiply by that number to get the total number of stims.
        opts.specific.genPlaylist.Randomize = 'lists&within'; % randomize list order and stimuli within each list.
        opts.specific.genPlaylist.Repeats = 'allbefore'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % don't append the generated lists to the USedList file by default. We'll want SIN_runTest to handle this and only do so if the test exits successfully.         
        
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
            'record_mic',       false, ...   % record playback and vocal responses via recording device. 
            'randomize',        false, ...   % randomize trial order before playback
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'startplaybackat',    0, ...  % start playback at beginning of files
            'mod_mixer',    fillPlaybackMixer(opts.player.playback.device, [ [0; 1] [0; 0 ] ], 0), ... % play HINT target speech to first channel only
            'state',    'run'); % Start in run state
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',         @modcheck_HINT_GUI, ...
            'data_channels',    2, ...
            'physical_channels', 1, ...
            'scored_items',  'allwords', ... % score all words. 
            'algo',     'oneuponedown', ... % use a one-up-one-down algo
            'score_labels',   {{'Correct', 'Incorrect'}}); % scoring labels for GUI
        
        % ============================
        % Modifier configuration        
        % ============================
        
        % Modifier to scale mixing information
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_dBscale_mixer, ... % use a decibel scale, apply to mod_mixer setting of player
            'mod_stage',    'premix',  ...  % apply modifications prior to mixing
            'dBstep',   [4 2], ...  % use variable step size. This matches HINT as normally administered
            'change_step', [1 5], ...   % This matches HINT as normally administered. 
            'data_channels', 2, ...
            'physical_channels', 1);  % apply decibel step to discourse stream in first output channel 
        
        % Modifier to track mod_mixer settings
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_trackMixer, ...
            'mod_stage',    'premix');   % track mod_mixer        
         
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
        opts(1)=SIN_TestSetup('ANL (MCL-Too Loud)', subjectID); 
        opts(2)=SIN_TestSetup('ANL (MCL-Too Quiet)', subjectID); 
        opts(3)=SIN_TestSetup('ANL (MCL-Estimate)', subjectID); 
        opts(4)=SIN_TestSetup('ANL (BNL-Too Loud)', subjectID); 
        opts(5)=SIN_TestSetup('ANL (BNL-Too Quiet)', subjectID); 
        opts(6)=SIN_TestSetup('ANL (BNL-Estimate)', subjectID); 
        
    case 'ANL (MCL-Too Loud)'
        % ANL (MCL-Too Loud) is the first step in the ANL sequence. The
        % listener is instructed to adjust the speech track until it is too
        % loud. 
        
        % Get base
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID;
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'You will listen to a story through the loudspeaker. These hand held buttons will allow you to make adjustments (Show the subject the buttons). When you want to turn the volume up - push this button (point to the up button), and when you want to turn the volume down - push this button (point to the down button). I will instruct you throughout the experiment. ' ...
            'Now I will turn the story on. Using the up button, turn the level of the story up until it is too loud (i.e., louder than most comfortable). Each time you push the up button, I will turn the story up.' };
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0] [0; 0] ]; % just discourse in first channel 
        
    case 'ANL (MCL-Too Quiet)'
        
        % This is just like the ANL (base), but with different
        % instructions and a different starting buffer position.
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Using the down button, turn the level of the story down until it is too soft (i.e., softer than most comfortable). Each time you push the down button, I will turn the story down (use 5 dB steps)'};
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0] [0; 0] ]; % just discourse in first channel 
        
    case 'ANL (MCL-Estimate)' 
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Now turn the level of the story back up to until the story is at your most comfortable listening level (i.e., or your prefect listening level) (use 2 dB steps).'};           
        
        % Change step size to 2 dB
        warning('Hard coded modifier number');
        if ~isfield(opts.player.modifier{2}, 'dBstep'), error('Something wrong here'); end        
        opts.player.modifier{2}.dBstep = 2; 
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0] [0; 0] ]; % just discourse in first channel 
        
    case 'ANL (BNL-Too Loud)'
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Now Iím going to leave the level of the story at this level (i.e., MCL) and turn on some background noise. Your up/down buttons will adjust the level of the background noise. Using the up button, turn the level of background noise up until you canít hear the story. Each time you push the up button, I will turn the background noise up (use 5 dB steps).'};           
        
        opts.player.modifier{2}.data_channels=2; 
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0.5] [0; 0] ]; % discourse channel and babble to first channel only
        
    case 'ANL (BNL-Too Quiet)' 
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Using the down button, turn the level of the background noise down until the story is very clear (i.e., you can follow the story easily). Each time you push the down button, I will turn the level of the background noise down (use 5 dB steps).'};           
        
        opts.player.modifier{2}.data_channels=2; 
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0.5] [0; 0] ]; % discourse channel and babble to first channel only
        
    case 'ANL (BNL-Estimate)'
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Good. Now turn the level of the background noise back up to the MOST noise that you would be willing to put-up-with and still follow the story for a long period of time without becoming tense or tired.'};           
        
        % Change step size to 2 dB and other information
        warning('Hard coded modifier number');
        if ~isfield(opts.player.modifier{2}, 'dBstep'), error('Something wrong here'); end        
        opts.player.modifier{2}.dBstep = 2; 
        opts.player.modifier{2}.data_channels=2; 
        
        % Set mixer
        opts.player.mod_mixer=[ [0.5; 0.5] [0; 0] ]; % discourse channel and babble to first channel only
        
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
        opts=SIN_TestSetup('Defaults', subjectID);
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID=testID;
        
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
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 0; % No lists to choose from
        opts.specific.genPlaylist.Randomize = ''; % No stimuli to randomize
        opts.specific.genPlaylist.Repeats = ''; % irrelevant since there aren't any lists        
        opts.specific.genPlaylist.Append2UsedList = false; % don't append the generated lists to the USedList file by default. We'll want SIN_runTest to handle this and only do so if the test exits successfully. 
        
        % ============================
        % Playback configuration
        %
        %   CWB running into issues with playback buffer size. Needs to be
        %   longer for longer files (due to indexing overhead)
        %
        % ============================
        
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
            'mod_mixer',    [ [0.5; 0.5] [0; 0] ], ... % Play both channels to left ear only. 
            'state',    'pause'); % start in paused state
        
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',  @ANL_modcheck_keypress, ...     % check for specific key presses
            'instructions', {{'You will listen to a story through the loudspeaker. These hand held buttons will allow you to make adjustments (Show the subject the buttons). When you want to turn the volume up - push this button (point to the up button), and when you want to turn the volume down - push this button (point to the down button). I will instruct you throughout the experiment.'}}, ...
            'keys',     [KbName('i') KbName('j') KbName('p') KbName('q') KbName('r')], ...  % first key makes sounds louder, second makes sounds quieter, third for pause, fourth for quit, fifth for run             
            'map',      zeros(256,1), ...
            'title', 'Acceptable Noise Level (ANL)');
%             'fhandle', @modcheck_ANLGUI, ...
            
        % Assign keys in map
        opts.player.modcheck.map(opts.player.modcheck.keys)=1; 
        
        % ============================
        % Modifier configuration                
        % ============================
        
        % Modifier to scale mixing information
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_dBscale_mixer, ... % use a decibel scale, apply to mod_mixer setting of player
            'mod_stage',    'premix', ... % run modification prior to mixing. 
            'dBstep',   5, ...  % use constant 1 dB steps
            'change_step', 1, ...   % always 1 dB
            'data_channels', 1, ...
            'physical_channels', 1);  % apply decibel step to discourse stream in first output channel 
        
        % Modifier to track mod_mixer settings. Used by other functions for
        % plotting purposes. Note that modifier_trackMixer should always be
        % at the END of the modifier list, since other modifiers might also
        % modify the mixing matrix. 
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_trackMixer, ...
            'mod_stage',    'premix');   % track mod_mixer            
           
    case 'MLST (Audio)'
        
        % Configured to administer the (audio only) MLST. Different
        % parameters required for the audiovisual version
        
        % Use the HINT as a starting point
        %   - The HINT is quite similar to the MLST in many ways, so let's
        %   use this as a starting point. 
        opts = SIN_TestSetup('HINT (SNR-50, Sentence-Based)', subjectID); 
        
        % Change the test ID
        opts.specific.testID = testID;
        
        % Change root directory
        opts.specific.root=fullfile(opts.general.root, 'playback', 'MLST (Adult)');
        
        % Change the wav_regexp
        %   We are using MP3 format here.
        opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp3$'; 
        
        % Change list_regexp
        %   MLST has an underscore in list directories.
        opts.specific.list_regexp='List_[0-9]{2}'; 
        
        % Change sentence lookup information
        %   This is used for scoring purposes
        opts.specific.hint_lookup.filename=fullfile(opts.specific.root, 'MLST (Adult).xlsx');
        opts.specific.sheetnum=1; % Check. 
        
    case 'MLST (AV)'
        
        % Configured to adminster the audiovisual (AV) MLST.
        
        error('Not yet developed'); 
    otherwise
        
        error('unknown testID')
        
end % switch 

%% ADD UUID TO STRUCTURE
%   - Assigns (or overwrites) a UUID.
opts = SIN_assignUUID(opts); 

%% WHERE TO SAVE DATA??
%   Save all data in the top-level directory for each subject. Originally
%   CWB had all testing materials in a separate folder for each test
%   (subfolders for each subject), but with the addition of a UUID, this
%   became unnecessary. 
%
%   File output takes the format of 
%     UUID;subject ID; test ID
%
%   CWB decided to list the UUID first so multipart tests list together in
%   the browser (easier to spot by eye). 
for i=1:length(opts)
    opts(i).specific.saveData2mat = fullfile(opts.subject.subjectDir, [opts.specific.uuid '-' opts.subject.subjectID '-' opts.specific.testID]);
end %