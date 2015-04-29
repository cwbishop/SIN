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

%% GLOBAL VALUES

% Below are a list of correction factors that must be applied under various
% playback conditions. Note that at time of writing, these correction
% factors should only be applied to MLST. The only other test with
% multi-channel maskers is the Hagerman, but the correction factor is dealt
% with implicitly in the call to createHagerman (see line 292 of
% createHagerman). 
% mlst_ists_4speaker_correction_db = -6.0147;
% mlst_spshn_4speaker_correction_db = -6.0262;

% Although the "theoretical" correction necessary to hit 75 dB from the 4
% speakers is about -6 dB, CWB's empircal measures showed that we needed to
% adjust by ~2 dB (to ~4 dB) to hit 75 dB noise levels). He took these
% measures at UW using the RadioShack handheld SLM. 
%
% Wu took a measurement with Larsen Davis mic and SLM and found the 4
% speaker noise to be TOO LOUD. Confirmed that they were spot on with the
% cheap radioshack SLM, however. So need to adjust back to -6 dB and
% confirm with Larson Davis SLM. These aren't strictly 6 dB, but they're
% close enough that it won't matter much. 
mlst_ists_4speaker_correction_db = -6;
mlst_spshn_4speaker_correction_db = -6; % 

if ~exist('testID', 'var') || isempty(testID), 
    testID='testlist'; 
end 

% Assign a default subjectID
if ~exist('subjectID', 'var'), subjectID = ''; end

% This is a site specific tag used to distinguish stimuli in the rare cases
% where stimuli *must* differ across sites. At the time of writing, the
% MLST channel mapping differs between UofI and UW. All other stimuli,
% however, are identical. 
%
% Mapping is based on the first digit of the subject ID
if ~isempty(subjectID) && isequal(subjectID(1), '2')
    SITE_EXT = '_UofI';
else    
    
    % The UW mapping is the "normal" mapping most people will want/need. 
    SITE_EXT = '_UW';
    
end % 

switch testID
    
    case 'testlist'
        
        % Hard code available tests
        %   CWB does not want users calling some tests directly from GUI
        %   intentionally or otherwise. Most straightforward way to
        %   control the tests is to manually list which tests are OK to
        %   use.
        
        
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
        
        % instructions directory
        opts.general.instruction_dir = fullfile(opts.general.root, 'instructions'); 
        
        % Subject directory
        opts.general.subjectDir = fullfile(opts.general.root, 'subject_data'); 
        
        % subject ID motif. Described using regexp. Used in
        % SIN_register_subject.m
        %
        % CWB relaxed this to allow any subject ID format. Proved useful
        % when using SIN for other studies (e.g., McClannahan's study)
        %
        % .* just means it has to have SOME character in there. No
        % formatting, though. 
        opts.general.subjectID_regexp='.*';
        
        % List SHA-1 key for SIN's Git repository
        %   This may prove useful when trying to recreate specific testing
        %   circumstances to recreate errors. 
        opts.general.git.sha = git_sha(opts.general.root);        
        
        % List of available tests
        %   This will vary by project. Field used to generate test list in
        %   SIN_GUI. CWB does not recall using it elsewhere. 
        opts.general.testlist = SIN_TestSetup('testlist', ''); 
        
        % Add computer information
        [status, hostname] = system('hostname');
        if status
            error('Could not find hostname'); 
        else
            opts.general.computer.hostname = deblank(hostname); 
        end % if ~status
        
        % Set subject information
        %   - Set subject identifier (subjectID)
        %   - Set subject-specific directory. This is different from the
        %   subjectDir found in the general field. 
        opts.subject.subjectID = subjectID; 
        opts.subject.subjectDir = fullfile(opts.general.subjectDir, opts.subject.subjectID); 
        
        % Set sound output paramters. 
        [playback_device, playback_map] = portaudio_GetDevice(fullfile(opts.general.root, 'playback_device.mat'), ...
                        'title', 'Playback Device Selection', ...
                        'prompt', 'Select ONE playback Device', ...
                        'mat_file', fullfile(opts.general.root, 'playback_device.mat'), ...
                        'max_selections', 1, ...
                        'field_name', 'NrOutputChannels');
   
        opts.player.playback = struct( ...
            'device', playback_device, ...    
            'block_dur', 0.5, ... % 500 ms block duration.            
            'internal_buffer', 4096); % used in 'buffersize' input to PsychPortAudio('Open', ...
        
        % Set playback map parameter for player_main
        opts.player.playback_map = playback_map; 
        
        % Recording device
        [record_device, record_map] = portaudio_GetDevice(fullfile(opts.general.root, 'recording_device.mat'), ...
                        'title', 'recording Device Selection', ...
                        'prompt', 'Select ONE recording Device', ...
                        'mat_file', fullfile(opts.general.root, 'recording_device.mat'), ...
                        'max_selections', 1, ...
                        'field_name', 'NrInputChannels');
                        
        opts.player.record = struct( ...
            'device', record_device, ...
            'buffer_dur', 60*60); % use a ridiculously long buffer duration 
        
        % Set record_map
        opts.player.record_map = record_map; 
        
        % Stop playback if we encounter an error
        opts.player.stop_if_error = true; 
        
        % Add player control modifiers
        %   Include a basic playback controller to handle "pauses",
        %   "resume", and "quit" requests.
        %   No, we don't want this added by default. Only to ANL
        opts.player.modifier={}; 
        
        % Where the UsedList is stored. 
        opts.specific.genPlaylist.UsedList = fullfile(opts.subject.subjectDir, [opts.subject.subjectID '-UsedList.mat']); % This is where used list information is stored.
        
        % Preload stimuli by default
        %   Generally do not want to preload AV stims, though, so look for
        %   a change in MLST (AV). Also MLST (Audio)
        opts.player.preload = true;
        
        % Analysis defaults
        %   Empty analysis function handle and parameters. Set 'run' to
        %   false so SIN_runTest does not attempt to run an analysis by
        %   default. 
        opts.analysis = struct(...
            'fhand',    '', ...
            'run',  false, ...
            'params', struct()); 
        
        % Return so we do not assign a UUID to defaults. 
        return
        
    case 'Record Calibration Tone'        
        
        % This is a bear bones test to create a fixed-duration recording.
        % The basic approach is to hook up a calibrator to our microphones,
        % ask the user what the output levels of the calibrator is (e.g.,
        % 124 dB SPL), then record the tone for a fixed time frame.
        
        % Use the Hagerman as a starting point since that just does
        % playback and recording of sound files. We'll create a temporary
        % file of a fixed length (say, 20 seconds) and add in some user
        % prompts along the way during test setup. That should make things
        % relatively painless.
        %% SETUP FOR HAGERMAN STYLE RECORDINGS
        %   This specific experiment has some basic needs. 
        %       - Play back and record a specific set of files in
        %       randomized order. 
        %       - Create some plots/summary statistics after run time. 
        %   That's it! Let's see how quickly that can be done ...
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
        opts.specific.root=fullfile(opts.general.root, 'playback', 'Hagerman');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp=''; 
                
        % Set regular expression for wav files
        opts.specific.wav_regexp = 'spshn;bandpass;0dB[(noise floor)]'; % Use calibrated noise files (calibrated to 0 dB)
        
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
                
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 1; % Set to 1 since we are essentially presenting '1 list'
        opts.specific.genPlaylist.Randomize = ''; % randomize playback order. 
        opts.specific.genPlaylist.Repeats = 'any'; % 
        opts.specific.genPlaylist.Append2UsedList = false; % Theres not really anything here to track, so don't worry about adding it to the used stimulus list. 
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @player_main; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'none', ... % 'bytrial' means modchecks performed after each trial.
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'playertype',       'ptb (standard)', ... % use standard PTB playback. Streaming can introduce issues.                          '
            'mod_mixer',    fillPlaybackMixer(opts.player.playback_map, [0;0;0;0;0;0], 0), ... % play stimuli at full amplitude. They are already scaled in the files. 
            'startplaybackat',    0, ...  % start playback at beginning of files
            'contnoise',    [], ... % no continuous noise to play (for this example) 
            'wait_for_stop',    true,   ... % Wait for sound playback to end before returning control to player_main
            'state',    'run'); % Start in run state
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(); % Empty modcheck (don't need one here)
        
        % ============================
        % Modifier configuration        
        % ============================
        %   No modifiers for playback
        % Modifier to scale mixing information
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_ShowInstructions, ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'record_calibration_tone.txt')), ...
            'header', sprintf(['Calibrate Channel 1 (Left)']), ... % header
            'mod_stage', ''); 
               
        % Prompt user for calibration level and store it in the specific
        % field. Also ask for details about calibration tone frequency and
        % mic gain levels. These will be important for estimating absolute
        % levels when necessary. 
        cal_info = inputdlg({'Enter the SPL of the calibration tone in dB', ...
            'Enter calibration tone frequency in Hz.', ...
            'Enter the gain for the LEFT microphone (Channel 1) in dB.', ...
            'Enter the gain for the RIGHT microphone (Channel 2) in dB'});
        opts.specific.cal_info.cal_tone_db = cal_info{1};
        opts.specific.cal_info.cal_tone_hz = cal_info{2};
        opts.specific.cal_info.mic_gain = {cal_info{3:4}}';
       
        % Duplicate test for second channel.
        opts(2) = opts; 
        
        % Change analysis function (we don't need one).
        
    case 'Calibrate Speaker Levels'
        
        % The calibration routine is pretty straightforward. All we need to
        % do is to loop the playback of a calibration stimulus (e.g.,
        % broadband noise) and have the experimenters adjust amp settings
        % until a desired SPL is met.
        
        % Use ANL (base) as a starting point)
        opts = SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change test ID
        opts.specific.testID = testID; 
        
        % Turn off recordings
        %   We don't want to do recordings during this phase because
        %   KEMAR's mics should be off anyway. 
        %
        %   Actually, we may need this in specific circumstances, so leave
        %   it in just in case we need it later. 
        %
        %   CWB had to disable this on Wu's machine since he was running
        %   into memory errors. 
        opts.player.record_mic = false; 
        
        % Change root directory (for wavfile selection) and change
        % wav_regexp to choose correct calibration file
        opts.specific.root= fullfile(opts.general.root, 'playback', 'Noise');
        opts.specific.wav_regexp = 'HINT-SPSHN;bandpass;0dB.wav';
%         warning('Hint noise needs to be changed back'); 
%         opts.specific.wav_regexp = 'HINT-Noise.wav';
        
        % Don't write noise file to UsedList
        %   Not necessary since we're just using this for calibration
        %   purposes. 
        opts.specific.genPlaylist.Append2UsedList = false; 
        
        % Change the mixer to match the single channel calibration sound
        %   Initializes with zeros
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, [], 0);
        
        % Reset instructions for modcheck
        opts.player.modcheck.instructions = fileread(fullfile(opts.general.instruction_dir, 'calibrate_speaker_output.txt')); 
        
        % Redo key mapping to prevent users from increasing/decreasing
        % volume.
        %
        % 050318 CWB: Discovered this doesn't work properly. Need to remove
        % the modifiers to prevent scaling. 
         opts.player.modcheck.map(opts.player.modcheck.keys(1:2))=false; 
        
        % Remove all modifiers and add in the ones we want.
        opts.player.modifier = {struct()}; 
        
        % Add in playback control.
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_PlaybackControl, ...
            'mod_stage',    'premix');  % Apply during premixing phase. 
        
        % Now create a test stage for each speaker in turn. All we should
        % have to do is modify the mod_mixer to present the sound from the
        % next speaker.
        for i=1:opts.player.playback_map.channel_number
            
            % Set channel to "on"
            cal(i) = opts;            
            cal(i).player.mod_mixer(1, i) = 1;
            
            % Change title 
            %   Need to increment channel_map to be 1 index rather than 0. 
            cal(i).player.modcheck.title = [testID ': Speaker ' num2str(i) ' of ' num2str(opts.player.playback_map.channel_number)]; 
            
        end % for i=1:opts ...        
        
        % Reset options
        opts = cal; 
        
    case 'Calibrate Windows Media Player'
        
        % Play the calibration stimulus through windows media player.
        
        % 
        calibration_file = fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-SPSHN;bandpass;0dB.wav');
        
        % Write a two channel version of the file
        [cal, fs] = SIN_loaddata(calibration_file); 
        info = audioinfo(calibration_file);       
        
        % We need to route the calibration sound to either channel 1 (UW)
        % or channel 2 (U of I). We can use the SITE_EXT to determine which
        % site we are at
        if isequal(SITE_EXT, '_UW')
            cal = [cal zeros(size(cal))];
        elseif isequal(SITE_EXT, '_UofI')
            cal = [zeros(size(cal)) cal];
        end % if isequal(SITE_EXT ...
        
        [PATHSTR,NAME,EXT] = fileparts(calibration_file);         
        output_file = fullfile(PATHSTR, [ NAME '2CHAN' EXT]);
        audiowrite(output_file, cal, fs, 'BitsPerSample', info.BitsPerSample); 
        [PATHSTR,NAME,EXT] = fileparts(output_file);         
        % Setup player for playback through windows media player. We'll use
        % the MLST as a starting point 
        opts = SIN_TestSetup('MLST (Audio, Practice)', subjectID); 
        
        % Change test ID
        opts.specific.testID = testID; 
        
        % Change file lookup information around 
        opts.specific.root = fullfile(opts.general.root, 'playback', 'Noise');
        opts.specific.list_regexp = '';
        opts.specific.wav_regexp = [NAME EXT];
        
        % We don't need a mod check
        opts.player.modcheck = struct();
        
        % We don't need any modifiers, except instructions, which we'll add
        % in below.
        opts.player.modifier = {struct()};
        
        % Add in instructions
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_ShowInstructions, ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'calibrate_windows_media_player.txt')), ...
            'header', sprintf(['Instructions: ' testID]), ... % header
            'mod_stage', '');
        
        % Set lists to 1 so playlist generation won't buck
        opts.specific.genPlaylist.NLists = 1;
        
        % Also clear out lists field from MLST call
        opts.specific.genPlaylist.lists = {}; 
    case 'Audio Test (10 Hz click train)'
        
        % A test to perform a timing test of the playback/recording loop.
        % Eventually, this will playback a 10 Hz click train several times
        % and record it. The recordings will then be compared and
        % "realigned" to assess how stable the timing is.
        
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
        opts.specific.root=fullfile(opts.general.root, 'playback', 'calibration');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp=''; 
                
        % Set regular expression for wav files
        opts.specific.wav_regexp = '.wav'; % Use calibrated noise files (calibrated to 0 dB)

        % Set instructions
        
%         opts.player.modcheck.instructions = fileread(fullfile(opts.general.instruction_dir, 'audio_level_timing_test.txt')); 
        
        % Now reset genPlaylist information so it won't buck when called
        % from SIN_runTest.
        opts.specific.genPlaylist.NLists = 1; % Set to 1, we'll just use the one "list"
        opts.specific.genPlaylist.Randomize = ''; % just shuffle the lists, present stimuli in fixed order within each list.
        opts.specific.genPlaylist.Repeats = 'any'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
        % Get playlist so we can repeat the same recording many times
        [playlist, opts.specific.genPlaylist.lists] = SIN_getPlaylist(opts); 
        
        opts.specific.genPlaylist.files = repmat({playlist{1}}, 10, 1); 
        
        % Now alter genPlaylist struct so it won't break in SIN_runTest
        opts.specific.genPlaylist.NLists = 0; 
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @player_main; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'bytrial', ... % 'bytrial' means modchecks performed after each trial.
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'playertype',       'ptb (standard)', ... % use standard PTB playback. Streaming can introduce issues.  
            'startplaybackat',    0, ...  % start playback at beginning of files
            'mod_mixer',    fillPlaybackMixer(opts.player.playback_map, [1], 0), ... % play HINT target speech to first channel, spshnoise to second channel. Start with -10 dB SNR
            'contnoise',    [], ... % no continuous noise to play (for this example) 
            'wait_for_stop',    true, ... % wait for sound playback to stop before returning control to player_main. 
            'state',    'run'); % Start in run state
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct();               
                
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        
        % Instructions "modifier"
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_ShowInstructions, ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'audio_level_timing_test.txt')), ...
            'header', sprintf(['Instructions: ' testID]), ... % header
            'mod_stage', '');     
        
        % ============================
        % Analysis        
        % ============================
        opts.analysis = struct( ...
            'fhand',    @analysis_AudioTest, ...  % functioin handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function (analysis_HINT)
                'plot',     true, ... % generate plot
                'chans',    [1 2], ...% only perform analyses on channels 1 and 2
                'dBtol',    1, ... % 1 dB tolerance is OK.        
                'apply_filter', true, ...   % apply a high pass filter to the data. This removes low-frequency drift. 
                    'filter_order', 4, ...                    
                    'filter_frequency_range',   125, ...
                    'filter_type',  'high')); 
        
    case 'Reading Span'
        % Launch and run the reading span test provided by Thomas Lunner
        % and friends.
        
        % Get default structure
        %   Much of this information is not useful, though. Not sure if we
        %   should keep it.
        opts = SIN_TestSetup('Defaults', subjectID); 
        
        opts.specific.testID = testID;
        opts.specific.root = 'C:\\readingspan';
        opts.specific.list_regexp = '';
        opts.specific.wav_regexp = ''; 
        
        % Change the "player" to SIN_runsyscmd
        %   This will execute arbitrary commands at the system terminal.
        %   Useful when launching executables.
        opts.player = struct( ...            
            'player_handle',    @SIN_runsyscmd, ...
            'cmd',  '"Reading span 131022.exe"'); % this is the only (required) input argument
        
        % Add fields to generate playlist field. 
        %   Just placeholders since this isn't actually useful information.
        opts.specific.genPlaylist.NLists = 1;
        opts.specific.genPlaylist.Randomize = 'any';
        opts.specific.genPlaylist.Repeats = 'any';
        opts.specific.genPlaylist.Append2UsedList = false; % there's nothing to append to the used list mat file, so just tell it not to.             
        
    case 'Word Span (70 dB SPL)'    
        
        % This administers the Word Span, an auditory analog of the Reading
        % Span. This should be reasonably straight forward to do; it will
        % essentially be the HINT with a different scoring GUI and no
        % modifications made to the SNR. So, use the SNR as a base. 
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID);        
        
        % We only want the second half of the test
        opts = opts(2); 
        
        % Change the test ID
        opts.specific.testID = testID; 
        
        % Change root directory
        opts.specific.root = fullfile(opts.general.root, 'playback', 'Word Span'); 
        
        % Change the list regular expression and wav reg expression
        %   Note: CWB had an error in the wav_regexp. He was grabbing the
        %   uncalibrated sounds! Silly!
        opts.specific.list_regexp = 'List[0-9]{2}';
        opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB.wav$';
        
        % Remove the hint lookup table
        %   CWB has *finally* removed this poorly named field with
        %   'lookup_table'
        opts.specific = rmfield(opts.specific, 'hint_lookup');
        opts.specific.lookup_table = struct( ...
            'path_to_table', fullfile(opts.specific.root, 'WordSpan;bandpass;0dB.xlsx'), ...
            'Sheet', 1); 
        
        % Setup list selection
        %   Need to remove some specific crap from setting up HINT
        %   playlists before run time. We'll randomize list selection
        %   across listeners. 
        opts.specific.genPlaylist.NLists = 1;
        opts.specific.genPlaylist.Repeats = 'allbefore';
        opts.specific.genPlaylist.Randomize = 'lists';
        opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'files');
        opts.specific.genPlaylist = rmfield(opts.specific.genPlaylist, 'lists');
        
        % Replace the modification check
        %   At time of writing, no input parameters needed.
        opts.player.modcheck = struct( ...
            'fhandle',  @modcheck_wordspan_gui);
        
        % Clear the modifiers
        %   We don't need to track anything for this test, really. 
        opts.player.modifier = {}; 
        
        % Set volume to 1
        %   The calibrated sounds are single-channel files. These should be
        %   scaled to db(1) + db(+gain) where gain is the difference
        %   between the desired output level and 65 dB SPL. 
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, db2amp(+5), 0);
        
        % Replace analysis
        %   Currently does not require any parameters. 
        opts.analysis = struct( ...
            'fhand',    @analysis_WordSpan, ...
            'run',  true, ...
            'params',   struct); 
        
        % Add in instructions modifiers
        %   These modifiers will present instructions on specific trial
        %   numbers.
        
        % Practice instructions
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 0,  ...
            'header',   'Practice Trials (2)', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_practice.txt'))); 
            
        % Now we're starting the real deal!
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 3,  ...
            'header',   'Two Word Set', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_two_words.txt'))); 
        
        % Start 3 word sets!
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 8,  ...
            'header',   'Three Word Set', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_three_words.txt'))); 
        
        % Start 4 word sets!
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 13,  ...
            'header',   'Four Word Set', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_four_words.txt'))); 
        
        % Start 5 word sets!
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 18,  ...
            'header',   'Five Word Set', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_five_words.txt'))); 
        
        % Start 6 word sets!
        opts.player.modifier{end+1} = struct(...
            'fhandle',  @modifier_instructions_by_trial, ...
            'trial_number', 23,  ...
            'header',   'Six Word Set', ...
            'body', fileread(fullfile(opts.general.instruction_dir, 'wordspan_six_words.txt'))); 
        
        % Analysis
        opts.analysis = struct( ...
            'fhand',    @analysis_WordSpan, ...  % functioin handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct( ...
                'plot', true)); % make summary plots. 
    case 'Word Span (80 dB SPL)'
        
        % This is *identical* to the Word SPan 70 dB test, except at 80 dB.
        % This is intended for users with PTA < 40 dB HL
        opts = SIN_TestSetup('Word Span (70 dB SPL)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change modmixer 
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, db2amp(+15), 0);
        
    case 'Word Span (90 dB SPL)'
        
        % This is *identical* to the Word SPan 70 dB test, except at 90 dB.
        % This is intended for users with PTA < 40 dB HL
        opts = SIN_TestSetup('Word Span (70 dB SPL)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change modmixer 
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, db2amp(+25), 0);
      
    case 'Word Span (70 dB SPL, diotic)'
        
        % This is *identical* to the Word SPan 70 dB test, except at 90 dB.
        % This is intended for users with PTA < 40 dB HL
        opts = SIN_TestSetup('Word Span (70 dB SPL)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change mod_mixer
        %   Need the speech routed to both ears. 
        opts.player.mod_mixer(1,2) = opts.player.mod_mixer(1,1);
        
    case 'Word Span (80 dB SPL, diotic)'
        
        % This is *identical* to the Word SPan 70 dB test, except at 90 dB.
        % This is intended for users with PTA < 40 dB HL
        opts = SIN_TestSetup('Word Span (80 dB SPL)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change mod_mixer
        %   Need the speech routed to both ears. 
        opts.player.mod_mixer(1,2) = opts.player.mod_mixer(1,1); 
        
    case 'Word Span (90 dB SPL, diotic)'
        
        % This is *identical* to the Word SPan 70 dB test, except at 90 dB.
        % This is intended for users with PTA < 40 dB HL
        opts = SIN_TestSetup('Word Span (90 dB SPL)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change mod_mixer
        %   Need the speech routed to both ears. 
        opts.player.mod_mixer(1,2) = opts.player.mod_mixer(1,1);      
        
    case 'ANL (Practice)'
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
        
    case 'ANL (Session One)'
        
        % Same as practice run.
        opts = SIN_TestSetup('ANL (Practice)', subjectID);
%         opts.specific.testID = testID; 
        
    case 'ANL (Session Two)'    
        
        % Same as practice run.
        opts = SIN_TestSetup('ANL (Practice)', subjectID);
%         opts.specific.testID = testID; 
    
    case 'ANL (Session Three)'
        
       % Same as practice run.
       opts = SIN_TestSetup('ANL (Practice)', subjectID);
       
       % Change testID
       %    We do NOT want to change the test ID here or SIN_runTest won't
       %    be able to track the buffer position.
%        for i=1:numel(opts)
%            opts(i).specific.testID = testID; 
%        end % for i=1:numel(opts) 

    case 'HINT (Practice)'
        
        % This is a practice session using SNR-50, SPSHN.
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID); 
        
        % Change subject ID and GO
        for i=1:numel(opts)
            opts(i).specific.testID = testID;             
        end % for i=1:numel(opts)
        
    case 'HINT (Perceptual Test, SPSHN)'
        
        % Perceived Performance Test (PPT) is a subjective measure of
        % performance on a HINT-style test. This should be otherwise
        % identical to 'HINT (SNR-50, keywords, 1up1down) algorithm.
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID);
        
        % Change testID
        for i=1:numel(opts)
            opts(i).specific.testID = testID; 
        end % for i=1:numel(opts)
        
        % Change scoring for explorative phase so it's based on sentences,
        % not keywords.
        opts(1).player.modcheck.scored_items = 'sentences';
        
        % Change the test ID to PPT so the correct scoring scheme is used.
%         opts(1).specific.testID = testID; 
        opts(2).specific.testID = testID; 
        
        % Change scoring method to PPT based scoring
        opts(2).player.modcheck.scored_items = 'sentences';
        
        % Change instructions for both parts of test
        % Also change scoring labels        
        for i=1:numel(opts)
            
            % Find the instructions modifier
            ind = getMatchingStruct(opts(i).player.modifier, 'fhandle', @modifier_ShowInstructions);
            
            opts(i).player.modifier{ind}.body = sprintf([...
                'Subject: After each sentence, indicate if you *felt* you understood ' ...
                '"ALL" or "NOT ALL" of the sentence. This is just your opinion.\n\n' ...
                'Experimenter: Score each sentence as "ALL" or "NOT ALL". ' ...
                'Press "Next" to continue to the next trial.']);
            
            opts(i).player.modifier{ind}.header = ['Instructions: ' testID];
            
            % Change scoring labels
            opts(i).player.modcheck.score_labels = {'all', 'not_all'}; % scoring labels for GUI
            
        end % for i=1:numel(opts)
        
        % Change scoring labels to something more intuitive
%         opts.player.modcheck.score_labels = {'C', 'Not_All'};

    case 'HINT (SNR-80, SPSHN)'
        
        % This will be very similar to HINT (SNR-50, keywords, 1up1down),
        % but will need to change the algorithm.
        opts=SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID); 
        
        % Change testID
        for i=1:numel(opts)
            opts(i).specific.testID = testID; 
        end % for i=1:numel(opts)
                
        % Change algorithm tracking
        %   Start with 1up1down, then switch to 4down1up after trial 4
        opts(2).player.modcheck.algo = {@algo_HINT1up1down @algo_HINT3down1up}; 
        opts(2).player.modcheck.startalgoat=[1 5]; 
        
        % Modify the termination conditions to track reversals after at
        % trial 5.
        modifier_index = getMatchingStruct(opts(2).player.modifier, 'fhandle', @modifier_exit_after);
        
        % Now find the correct termination function
        for i =1:numel(opts(2).player.modifier{modifier_index}.function_handles)
            if isequal(opts(2).player.modifier{modifier_index}.function_handles{i}, @modifier_exit_after_nreversals)
                function_index = i;
            end
        end %
        
        % Modify the reversal tracking start point (trial ~5)
        opts(2).player.modifier{modifier_index}.function_parameters{function_index}.start_trial = opts(2).player.modcheck.startalgoat(2);
        
        % Allow dynamic updating up the playlist if we reach the end.        
        %   Start by copying the specific.genPlaylist field over here
%         opts(2).player.modifier{end+1} = opts(2).specific.genPlaylist;
%         
%         % Add function handle
%         opts(2).player.modifier{end}.fhandle = @modifier_append2playlist; 
%         
%         % Modify genPlaylist settings
%         %   - Append a single list at a time. 
%         opts(2).player.modifier{end}.NLists = 1; 
%         opts(2).player.modifier{end}.Randomize = 'lists';
%         opts(2).player.modifier{end}.Repeats = 'allbefore'; 
%         opts(2).player.modifier{end}.Append2UsedList = false; 
%         opts(2).player.modifier{end}.files = {};   
        
        % Add analysis
        opts(1).analysis = struct();
        opts(1).analysis = struct( ...
            'fhand',    @analysis_HINT, ...  % function handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function (analysis_HINT)
                'channel_mask',    fillPlaybackMixer(opts(1).player.playback_map, [1;0], 0), ...   % just get data/physical channel 1                
                'RTSest',   'reversal_mean',  ... % specify first trial to include in average. Requires 'trial' field as well
                'start_at_trial', opts(2).player.modcheck.startalgoat(2), ... % Only want to look at the trials that are used for the 3down1up algo
                'start_at_reversal', 1,  ... % start at trial 4 (the first trial has been eaten up by the dynamic search)
                'trials_to_score', Inf, ... % we'll include all trials in our scoring, since the reversals can happen at any point. 
                'include_next_trial', true, ...
                'plot', true)); % generate plot
        
        opts(2).analysis = opts(1).analysis;   
        
    case 'HINT (SNR-80, ISTS)'   
        
        % SNR-80 estimation using ISTS as masker
        % Get a good starting point
        opts = SIN_TestSetup('HINT (SNR-80, SPSHN)', subjectID); 
        
        % Change test ID
        for i=1:numel(opts)
            opts(i).specific.testID = testID; 
        end % for i=1:numel(opts)
                
        % We need some file information from the HINT (SNR-50, ISTS)
        ists_opts = SIN_TestSetup('HINT (SNR-50, ISTS)', subjectID); 
        
        % Change wav_regexp and lookup table
        for i=1:numel(ists_opts)
            
            % Lookup table changes
            opts(i).specific.genPlaylist = ists_opts(i).specific.genPlaylist;
            opts(i).specific.hint_lookup = ists_opts(i).specific.hint_lookup;
            
            % wav file changes
            opts(i).specific.wav_regexp = ists_opts(i).specific.wav_regexp;
            
        end % for i=1:nuem(ists_opts)       
        
    case 'HINT (SNR-50, SPSHN)'
        
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
        opts.specific.list_regexp = 'List[0-9]{2}'; 
                
        % Set regular expression for wav files
        opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB[+]spshn.wav$'; % Use calibrated noise files (calibrated to 0 dB)
%         opts.specific.wav_regexp = '[0-9]{2}.wav$'; % Use calibrated noise files (calibrated to 0 dB)
        
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
        opts.specific.hint_lookup=struct(...
            'filename', fullfile(opts.specific.root, 'HINT (;bandpass;0dB+spshn).xlsx'), ...
            'sheetnum', 1); 
        
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 2; % The number of lists to include in the playlist. Most lists have a fixed number of stimuli, so multiply by that number to get the total number of stims.
        opts.specific.genPlaylist.Randomize = 'lists'; % just shuffle the lists, present stimuli in fixed order within each list.
        opts.specific.genPlaylist.Repeats = 'allbefore'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
        % Get the stimulus list that we need. We need to populate this
        % field here so we know which stimulus will be FIRST for the roving
        % part.
        [opts.specific.genPlaylist.files, opts.specific.genPlaylist.lists] = SIN_getPlaylist(opts); 
        
        % Now reset genPlaylist information so it won't buck when called
        % from SIN_runTest.
        opts.specific.genPlaylist.NLists = 0; % Set to 0 so SIN_getPlaylist won't buck later.
        opts.specific.genPlaylist.Randomize = ''; % just shuffle the lists, present stimuli in fixed order within each list.
        opts.specific.genPlaylist.Repeats = 'any'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @player_main; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'bytrial', ... % 'bytrial' means modchecks performed after each trial.
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'randomize',        false, ...   % randomize trial order before playback
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'playertype',       'ptb (standard)', ... % use standard PTB playback. Streaming can introduce issues.  
            'startplaybackat',    0, ...  % start playback at beginning of files
            'mod_mixer',    fillPlaybackMixer(opts.player.playback_map, [ [db2amp(-20); 1] [0; 0] ], 0), ... % play HINT target speech to first channel, spshnoise to second channel. Start with -10 dB SNR
            'contnoise',    [], ... % no continuous noise to play (for this example) 
            'wait_for_stop',    false,  ... % return control to player_main while sound playback is happening. This will bring up the scoring GUI.
            'state',    'run'); % Start in run state
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',         @modcheck_HINT_GUI, ...
            'data_channels',    1, ...
            'physical_channels', 1, ...
            'scored_items',  'keywords', ... % score only keywords (excludes articles?)
            'algo',     {{@algo_HINT1up1down}}, ... % use a one-up-one-down algo
            'startalgoat',     [1], ... % start algorithms at trials 1/5
            'score_labels',   {{'Correct', 'Incorrect'}}); % scoring labels for GUI
        
        % ============================
        % Modifier configuration        
        % ============================
        
        % Add a modifier to add on more files if we run out of files to
        % play before we reach the "exit" status. 
        
        % Modifier to scale mixing information
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_dBscale_mixer, ... % use a decibel scale, apply to mod_mixer setting of player
            'mod_stage',    'premix',  ...  % apply modifications prior to mixing
            'dBstep',   [4 2], ...  % use variable step size. This matches HINT as normally administered
            'change_step', [1 4], ...   % Switched to 4 because we lost a trial by doing the search sweep. 
            'data_channels', 1, ... % HINT speech coming out of data channel 1 (now) 
            'physical_channels', 1);  % apply decibel step to discourse stream in first output channel 
        
        % Modifier to track mod_mixer settings
        opts.player.modifier{end+1} = struct( ...
            'fhandle',  @modifier_trackMixer, ...
            'mod_stage',    'premix');   % track mod_mixer        
        
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_ShowInstructions, ...
            'body', sprintf(['Experimenter: Present and score each sentence ' ...
                            ' by clicking on the "correct" or "incorrect" ' ...
                            'button for each scored word. \n\n' ...
                            'After scoring a sentence, press "Next" to continue']), ...
            'header', sprintf('Instructions'), ... % header
            'mod_stage', '');         
        
        
            
        % ============================
        % Analysis        
        % ============================
        opts.analysis = struct( ...
            'fhand',    @analysis_HINT, ...  % functioin handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function (analysis_HINT)
                'channel_mask',    fillPlaybackMixer(opts.player.playback_map, [1;0], 0), ...   % just get data/physical channel 1                
                'RTSest',   'trial_mean',  ... % specify first trial to include in average. Requires 'trial' field as well
                'start_at_trial', 4,  ... % start at trial 4 (the first trial has been eaten up by the dynamic search)
                'include_next_trial', true, ...
                'trials_to_score', 17, ... % We're using two lists, so we want to include 17 total trials in scoring algorithm (see HINT manual)
                'plot', true)); % generate plot
    
        % ============================
        % Initial search code
        % ============================
        % This will be the first segment in HINT testing during which we present
        % the same stimulus repeatedly until the listener understands it
        % completely. 
        rove = opts;
        % Start with HINT (SNR-50 ... for starters
%         opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID);
        
        % Change testID
        %   This is hard-coded since it's the roving test at the beginning
        %   of the HINT.
        rove.specific.testID = testID; 
        
        % Add a modifier to stop playback after the first correct response
        % is recorded (that's 100% of scored words repeated correctly).
        rove.player.modifier{end + 1} = struct( ...
            'fhandle',  @modifier_exitAfter, ... % 
            'mod_stage',    'premix',  ...  % apply modifications prior to mixing
            'expression',   'mod_code == -1');         

        % Find scaling modifier. Once found, fix dBsteps to 4 dB
        ind = getMatchingStruct(rove.player.modifier, 'fhandle', @modifier_dBscale_mixer);
        rove.player.modifier{ind}.dBstep = 4; 
        rove.player.modifier{ind}.change_step = 1; 
        
        % Alter instructions for roving part of HINT
        ind = getMatchingStruct(rove.player.modifier, 'fhandle', @modifier_ShowInstructions);
        rove.player.modifier{ind}.body = sprintf('Experimenter: Repeat a single sentence until the listener repeats 100 percent of all target words correctly. This should terminate automatically.\n\nSubject: Listen to each sentence and repeat it aloud after the end of each sentence.');
        
        % Use a specific file for the roving portion of the test
        rove.specific.genPlaylist.files = repmat({opts.specific.genPlaylist.files{1}}, 20,1); 
        
        % Now put the two pieces together
        firstopts = opts;
        opts(1) = rove;
        opts(2) = firstopts; 
        
        % Don't need to run analysis after roving phase
        opts(1).analysis.run = false; 
        
        % Now remove first stimulus from playback list. HINT manual says we
        % should move onto second stimulus
        opts(2).specific.genPlaylist.files = { opts(2).specific.genPlaylist.files{2:end} }; 
        
        % Add a custom stop modifier to the second stage of the test
        %   This should force an exit status at the 
        opts(2).player.modifier{end+1}= struct( ...
            'fhandle',  @modifier_exit_after, ...
                'function_handles', {{@modifier_exit_after_nreversals @modifier_exit_trials}}, ...
                'operator', '&&', ...
                'function_parameters',  {{...
                    ... % Options for exit_after_nreversals
                    struct( ...
                        'data_channels',    opts(1).player.modcheck.data_channels, ...
                        'physical_channels',    opts(1).player.modcheck.physical_channels, ...
                        'max_revs', 7, ...
                        'start_trial', 1), ...
                    ... % Options for exit_trials 
                    struct( ...
                        'trial_number', 19, ... 
                        'trial_operator',   '>')}} ); 
          
        % We need to setup the rules for appending files if we run out of
        % stimuli to play before the exit criterion(a) are met. Start by
        % copying over the genPlaylist information. 
        opts(2).player.modifier{end+1} = opts(2).specific.genPlaylist;
        
        % We want to add lists until we reach the exit criteria. 
        opts(2).player.modifier{end}.fhandle = @modifier_append2playlist;     
        
        % Modify genPlaylist settings
        %   - Append a single list at a time. 
        opts(2).player.modifier{end}.NLists = 1; 
        opts(2).player.modifier{end}.Randomize = 'lists';
        opts(2).player.modifier{end}.Repeats = 'allbefore'; 
        opts(2).player.modifier{end}.Append2UsedList = false; 
        opts(2).player.modifier{end}.files = {};                   
        
    case 'HINT (SNR-50, ISTS)'
        
        % ISTS version of HINT test
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID); 
        
        % Change testID, wav_regexp, and the hint_lookup table
        for i=1:numel(opts)
            opts(i).specific.testID = testID;
            opts(i).specific.wav_regexp = '[0-9]{2};bandpass;0dB[+]4talker_ists.wav$'; % Use calibrated noise files (calibrated to 0 dB)
            opts(i).specific.genPlaylist.files = {};  
            opts(i).specific.genPlaylist.lists = {}; 
            
            % Change hint lookup file so we're looking at the ISTS stimuli
            opts(i).specific.hint_lookup.filename = strrep(opts(i).specific.hint_lookup.filename, '+spshn', '+4talker_ists');
            
        end % for i=1:numel(opts)
                    
        % Get different files
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts(2).specific.genPlaylist.NLists = 2; % The number of lists to include in the playlist. Most lists have a fixed number of stimuli, so multiply by that number to get the total number of stims.
        opts(2).specific.genPlaylist.Randomize = 'lists'; % just shuffle the lists, present stimuli in fixed order within each list.
        opts(2).specific.genPlaylist.Repeats = 'allbefore'; % All lists must be used before we repeat any.         
        opts(2).specific.genPlaylist.Append2UsedList = false; % don't append the lists here, that will be handled in SIN_runTest.
        
        % Get the stimulus list that we need. We need to populate this
        % field here so we know which stimulus will be FIRST for the roving
        % part.
        [opts(2).specific.genPlaylist.files, opts(2).specific.genPlaylist.lists] = SIN_getPlaylist(opts(2)); 
        
        % need to add lists to roving section of test
        opts(1).specific.genPlaylist.lists = opts(2).specific.genPlaylist.lists;
        
%         opts(2).specific.genPlaylist.files = SIN_getPlaylist(opts(2)); 
        
        % Now reset genPlaylist information so it won't buck when called
        % from SIN_runTest.
        opts(2).specific.genPlaylist.NLists = 0; % Set to 0 so SIN_getPlaylist won't buck later.
        opts(2).specific.genPlaylist.Randomize = ''; % just shuffle the lists, present stimuli in fixed order within each list.
        opts(2).specific.genPlaylist.Repeats = 'any'; % All lists must be used before we repeat any.         
        opts(2).specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
         % Use a specific file for the roving portion of the test
        opts(1).specific.genPlaylist.files = repmat({opts(2).specific.genPlaylist.files{1}}, 20,1); 
        
        % Now remove first stimulus from playback list. HINT manual says we
        % should move onto second stimulus
        opts(2).specific.genPlaylist.files = { opts(2).specific.genPlaylist.files{2:end} }'; 
        
    case 'HINT (Traditional, diotic)'
        
        % This administers the HINT as it is traditionally described,
        % albeit with sounds presented from a single speaker (or earphone).
        % Masker is SPSHN.
        
        % Start out with the SNR-50, SPSHN as a template.
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID);         
        
        
        for i = 1:length(opts)            
            
            opts(i).specific.testID = testID;  
            
            % Change mixer settings so we present the same stimulus to both
            % ears.
            opts(i).player.mod_mixer = fillPlaybackMixer(opts(1).player.playback_map, [ [db2amp(-20); 1] [db2amp(-20); 1] ], 0);
            
            % Modify test ID and change mod_mixer to play sounds diotically.         
            % Change the modifier_dbscale_mixer to change BOTH earphones
            % simultaneously.
            ind = getMatchingStruct(opts(i).player.modifier, 'fhandle', @modifier_dBscale_mixer);
            opts(i).player.modifier{ind}.physical_channels = [1 2];            
            
        end % 
                
        % Remove exit after modifier. We don't need to place any
        % constraints.
        %
        % Also remove the "append2playlist" modifier since we won't be
        % adding any stimuli.
        mods2remove = [getMatchingStruct(opts(2).player.modifier, 'fhandle', @modifier_exit_after) getMatchingStruct(opts(2).player.modifier, 'fhandle', @modifier_append2playlist)];
        mask = true(length(opts(2).player.modifier),1);
        mask(mods2remove) = false;
        opts(2).player.modifier = {opts(2).player.modifier{mask}}; 
        
        %% Allow user to select lists manually.
        
        % Get HINT lists to select
        [hint_lists, hint_files] =SIN_stiminfo(opts(2));
        
        % Compile short hand list selection
        hint_lists_short = {}; 
        for i = 1:length(hint_lists)
            [PATHSTR,NAME,EXT] = fileparts(hint_lists{i}(1:end-1)); 
            hint_lists_short{i} = NAME;             
        end % for i
        
        % Open selection GUI and select lists
        [selection_text, selection_index] = SIN_select(hint_lists_short, ...
            'title', 'HINT List Selection', ...
            'prompt', 'Select Lists to Test (Hold CTRL to Select Multiple Lists)', ...
            'max_selections', numel(hint_lists_short)); 
        
        % Add hint_files and lists to appropriate fields.
        %   This will ensure that list tracking is handled properly.
        playlist = concatenate_lists({hint_files{selection_index}});
        opts(2).specific.genPlaylist.files = {playlist{2:end}};
        opts(2).specific.genPlaylist.lists = {hint_lists{selection_index}}';
        
        % Replace stimuli in "roving phase" with the first stimulus. This
        % will be used to find the approximate start location for the
        % remainder of HINT.
        opts(1).specific.genPlaylist.files = repmat({playlist{1}}, 20, 1); 
        
        % Also add the lists here for accurate list tracking
        opts(1).specific.genPlaylist.lists = opts(2).specific.genPlaylist.lists;
        
        % Update analyses based on the number of stimuli presented. We want
        % to exclude the first 4 - 5 trials, depending on how we count.
        for i=1:length(opts)
                
            opts(i).analysis.params.trials_to_score = length(opts(2).specific.genPlaylist.files)  - 3;
            
            % If we are appending a trial to the scoring, then we'll want
            % to include this in the scoring as well.
            if opts(i).analysis.params.include_next_trial
                opts(i).analysis.params.trials_to_score = opts(i).analysis.params.trials_to_score + 1;
            end % if opts(i).analysis.params.include_next_trial
            
        end % for i=1:length(opts)
        
    case 'MLST (Audio, Practice)'
        
        % Practice session based on 'MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)'
        opts = SIN_TestSetup('MLST (Audio, Aided, ISTS, 75 dB SPL, +0 dB SNR)', subjectID); 
        
        % Change testID
        for i=1:numel(opts)
            opts(i).specific.testID = testID; 
            
            % Don't stop if we encounter an error.
            opts(i).player.stop_if_error = false;
            
        end % for i=1:numel(opts)
        
    case 'MLST (AV, Practice)'
        
        % Practice session based on 'MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)'
        opts = SIN_TestSetup('MLST (AV, Aided, ISTS, 75 dB SPL, +0 dB SNR)', subjectID); 
        
        % Change testID
        for i=1:numel(opts)
            opts(i).specific.testID = testID; 
            
            % Don't stop if we encounter an error.
            opts(i).player.stop_if_error = false;
            
        end % for i=1:numel(opts)
        
    case 'MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)'
        
        % Configured to administer the (audio only) MLST. This serves as
        % the basic setup file for all MLST files, so changes here will
        % (generally) be inherited by all other versions of MLST testing. 
        
        % Use the HINT as a starting point
        %   - The HINT is quite similar to the MLST in many ways, so let's
        %   use this as a starting point. 
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID); 
        opts = opts(2); % we don't need the first bit of the HINT (searching) 
        
        % Clear playlist
        opts.specific.genPlaylist.files =[]; 
        
        % Change the test ID
        opts.specific.testID = testID;
        
        % Change root directory
        opts.specific.root=fullfile(opts.general.root, 'playback', 'MLST (Adult)');
        
        % Change the wav_regexp
        %   Use the WAV files here, CWB thinks. 
        %
        %   Note that a site-specific tag is appended for the MLST due to
        %   an obligatory difference in channel mapping        
        opts.specific.wav_regexp = ['[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB' SITE_EXT  '.wav$']; 
        
        % Change list_regexp
        %   MLST has an underscore in list directories.
        opts.specific.list_regexp='List_[0-9]{2}'; 
        
        % Change sentence lookup information
        %   This is used for scoring purposes
        opts.specific.hint_lookup.filename=fullfile(opts.specific.root, ['MLST (Adult);bandpass;0dB' SITE_EXT '.xlsx']);
        opts.specific.hint_lookup.sheetnum=1;   
        
        % Now reset genPlaylist information so it won't buck when called
        % from SIN_runTest.
        opts.specific.genPlaylist.files = []; % we don't have any preset files we want to play (yet), so go with random list selection
        opts.specific.genPlaylist.NLists = 2; % Set to 1, we'll just use the one "list"
        opts.specific.genPlaylist.Randomize = 'lists'; % just shuffle the lists, present stimuli in fixed order within each list.
        opts.specific.genPlaylist.Repeats = 'allbefore'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
        % Change mod_mixer to work with single channel data
        %   Scale speech track to full volume, assuming we calibrate to 65
        %   dB SPL. 
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, [1 0], 0);
        
        % Change to 'wmp' mode
        opts.player.playertype = 'wmp';
        
        % Remove the modifier_dbBscale_mixer
        %
        % Also remove the exit after modifier. This is unncessary for this
        % test. 
        %
        % Also remove "append2playlist. We won't be doing that at all. 
        ind = [getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_dBscale_mixer) getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_exit_after) getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_append2playlist)];
        mask = true(length(opts.player.modifier),1);
        mask(ind) = false;
        opts.player.modifier = {opts.player.modifier{mask}}; 
        
        % For plotting purposes, track the first channel
        opts.player.modcheck.data_channels = 1; 
        
        % We aren't applying any changes. Just using the GUI for scoring. 
        opts.player.modcheck.algo = {@algo_HINTnochange}; %
        
        % Use keyword scoring only
        %   Keywords are denoted as capital letters. 
        opts.player.modcheck.scored_items = 'keywords'; 
        
        % This way the player doesn't waste time loading the files into a
        % matrix - we won't need these data in MATLAB since WMP will be
        % handling playback. 
        opts.player.preload = false; 
        
        %% CONTINUOUS NOISE INFORMATION
        %   Loads a file containing a 4-channel noise sample and plays the
        %   noise back from all 4 speakers. 
        %
        %   Note that we do NOT need a site extension here because these
        %   data are presented via SIN's player_main, which can handle
        %   arbitrary channel mapping
        opts.player.contnoise = fullfile(opts.general.root, 'playback', 'Noise', 'MLST_SPSHN_4_channel;bandpass;0dB.wav'); % File name
        opts.player.noise_mixer = fillPlaybackMixer(opts.player.playback_map, db2amp(-8 + mlst_spshn_4speaker_correction_db).*eye(4,4), 0); % Reduce noise output by -8 dB to create +8 dB SNR.
                                                                                                                  % ~ -6.05 dB corrects for level gain due to playing noise from multiple speakers.
                                                                                                                  % Together, these should target a -8 dB SNR very well. Here's hoping it does ;). 
                                                                                                                  % See the note link below here for details on how CWB estimated the 6.05 dB correction factor
                                                                                                                  % http://www.evernote.com/shard/s353/sh/a51a39a6-4732-4dfe-9040-840ba98945fd/9e1c5846a09fe0e7e3e3297c8a220380
        % ============================
        % Analysis        
        % ============================
        opts.analysis = struct( ...
            'fhand',    @analysis_MLST, ...  % functioin handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function (analysis_HINT)                
                'plot', true)); % generate plot      
            
    case 'MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)'
        
        % Just like aided 65 dB SPL test, but with different wav_regexp and
        % lookup
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', subjectID);
        
        opts.specific.testID = testID; 
        
        % Change Speech levels by selecting different speech files for
        % playback that have a +15 dB gain relative to our calibration file
        %   Note the brackets around the "+" sign to distinguish it from
        %   the + operator in regexp.
        opts.specific.wav_regexp = strrep(opts.specific.wav_regexp, ';0dB', ';[+]10dB');
        
        % Change lookup table 
        %   We have to have slightly different versions of the lookup table
        %   for 0dB and +15dB files since the lookup code (importHINT,
        %   specifically) does some basic string matching. 
        %  
        %   Note: Unlike wav_regexp below, we don't have to out the "+" in
        %   brackets since this is a simple string and not a regular
        %   expression. 
        opts.specific.hint_lookup.filename = strrep(opts.specific.hint_lookup.filename, ';0dB', ';+10dB');
        
        % Add 15 dB to account for the louder speech levels, then add 8 dB
        % to compensate for the -8 dB gain applied to noise in scaffold to
        % create +8 dB SNR. 
        %
        % In other words, we reduced the noise levels by 8 dB in the test
        % used as a scaffold, so add the 8 back in to get us back to 0 dB
        % SNR, then add another 15 dB on top of it to put us in the +15 dB
        % range. 
        opts.player.noise_mixer = opts.player.noise_mixer.*db2amp(10 + 8); % multiply to apply dB change
        
    case 'MLST (Audio, Aided, ISTS, 65 dB SPL, +8 dB SNR)'
        
        % Just swapping out the masker type.
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', subjectID);
        
        opts.specific.testID = testID; 
        
        % Swap out continuous noise with ISTS
        opts.player.contnoise = fullfile(opts.general.root, 'playback', 'Noise', 'MLST_ISTS_4_talker;bandpass;0dB.wav'); % File name
    
        % Need to change the mod_mixer to incorporate ISTS corrective
        % factor. 
        opts.player.noise_mixer = fillPlaybackMixer(opts.player.playback_map, db2amp(-8 + mlst_ists_4speaker_correction_db).*eye(4,4), 0);
        
    case 'MLST (Audio, Aided, ISTS, 75 dB SPL, +0 dB SNR)'
        
         % Just swapping out the masker type.
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', subjectID);
        
        % Replace test ID
        opts.specific.testID = testID; 
        
        % Swap out continuous noise with ISTS
        opts.player.contnoise = fullfile(opts.general.root, 'playback', 'Noise', 'MLST_ISTS_4_talker;bandpass;0dB.wav'); % File name
        
    case 'MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
        % Change wav_regexp to pull in MP4s
        %   Just replace the file .wav file extension with .mp4 and move on
        %   with our lives. 
        opts.specific.wav_regexp = strrep(opts.specific.wav_regexp, '.wav', '.mp4'); 
     
    case 'MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)'
        
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
        % Change wav_regexp to pull in MP4s
        opts.specific.wav_regexp = strrep(opts.specific.wav_regexp, '.wav', '.mp4'); 
        
    case 'MLST (AV, Aided, ISTS, 65 dB SPL, +8 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (Audio, Aided, ISTS, 65 dB SPL, +8 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
        % Change wav_regexp to pull in MP4s
        opts.specific.wav_regexp = strrep(opts.specific.wav_regexp, '.wav', '.mp4'); 
        
    case 'MLST (AV, Aided, ISTS, 75 dB SPL, +0 dB SNR)'
        
        opts = SIN_TestSetup('MLST (Audio, Aided, ISTS, 75 dB SPL, +0 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
        % Change wav_regexp to pull in MP4s
        opts.specific.wav_regexp = strrep(opts.specific.wav_regexp, '.wav', '.mp4'); 
        
    case 'MLST (Audio, Unaided, SPSHN, 65 dB SPL, +8 dB SNR)'    
        
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', subjectID);
        opts.specific.testID = testID; 
        
    case 'MLST (Audio, Unaided, SPSHN, 75 dB SPL, +0 dB SNR)'    
        
        opts = SIN_TestSetup('MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', subjectID);
        opts.specific.testID = testID;     
        
    case 'MLST (Audio, Unaided, ISTS, 65 dB SPL, +8 dB SNR)'    
        
        opts = SIN_TestSetup('MLST (Audio, Aided, ISTS, 65 dB SPL, +8 dB SNR)', subjectID);
        opts.specific.testID = testID; 
        
    case 'MLST (Audio, Unaided, ISTS, 75 dB SPL, +0 dB SNR)'    
        
        opts = SIN_TestSetup('MLST (Audio, Aided, ISTS, 75 dB SPL, +0 dB SNR)', subjectID);
        opts.specific.testID = testID; 
        
    case 'MLST (AV, Unaided, SPSHN, 65 dB SPL, +8 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
    case 'MLST (AV, Unaided, SPSHN, 75 dB SPL, +0 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
    case 'MLST (AV, Unaided, ISTS, 65 dB SPL, +8 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (AV, Aided, ISTS, 65 dB SPL, +8 dB SNR)', subjectID); 
        opts.specific.testID = testID;  
        
    case 'MLST (AV, Unaided, ISTS, 75 dB SPL, +0 dB SNR)'
        
        % Start with the audio condition
        opts = SIN_TestSetup('MLST (AV, Aided, ISTS, 75 dB SPL, +0 dB SNR)', subjectID); 
        opts.specific.testID = testID; 
        
    case 'Hagerman (Unaided, Record Clean Speech)'
        
        % Here, we record speech in the absence of noise. To do this, we
        % should be able to use the Hagerman (Unaided, SPSHN) and just 
        % change the wav_regexp field to select a single file for playback.
        % We only need to record the speech in one orientation, CWB thinks.
        opts = SIN_TestSetup('Hagerman (Unaided, SPSHN)', subjectID);
        
        % Change the test ID
        opts.specific.testID = testID;
        
        % Change the regular expression.
        opts.specific.wav_regexp = [opts.specific.wav_regexp ';00dB SNR;TorigNorig'];
        
        % Change the mixer settings so we only present the speech signal
        % from the front speaker
        opts.player.mod_mixer = zeros(size(opts.player.mod_mixer)); 
        opts.player.mod_mixer(1,1) = 1; % routes speech to front speaker 
        
    case 'Hagerman (Aided, ISTS, Set Mic Levels)'
        
        % Here we simply play a single file with the lowest SNR (-10 dB)
        % so the experimenter can set the mic levels accordingly. We'll use
        % the ISTS stimuli in this case. We'll make another test to deal
        % with SPSHN.
        opts = SIN_TestSetup('Hagerman (Unaided, ISTS)', subjectID); 
        
        % Change the test ID
        opts.specific.testID = testID; 
        
        % Change wav_regexp to get a single file at poorest SNR
        opts.specific.wav_regexp = [opts.specific.wav_regexp ';-10dB SNR;TorigNorig'];
        
    case 'Hagerman (Aided, SPSHN, Set Mic Levels)'
        
        opts = SIN_TestSetup('Hagerman (Unaided, SPSHN)', subjectID); 
        
        % Change the test ID
        opts.specific.testID = testID; 
        
        % Change wav_regexp to get a single file at poorest SNR
        opts.specific.wav_regexp = [opts.specific.wav_regexp ';-10dB SNR;TorigNorig'];
        
    case 'Hagerman (Unaided, SPSHN)'
        
        %% SETUP FOR HAGERMAN STYLE RECORDINGS
        %   This specific experiment has some basic needs. 
        %       - Play back and record a specific set of files in
        %       randomized order. 
        %       - Create some plots/summary statistics after run time. 
        %   That's it! Let's see how quickly that can be done ...
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
        
        % root directory for Hagerman stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'Hagerman');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp=''; 
             
        % Prompt user for calibration level and store it in the specific
        % field. 
        cal_info = inputdlg({'Enter the gain for the LEFT microphone (Channel 1) in dB.', ...
            'Enter the gain for the RIGHT microphone (Channel 2) in dB'});
        opts.specific.cal_info.mic_gain = cal_info;
        
        % Set regular expression for wav files
        opts.specific.wav_regexp = 'spshn;bandpass;0dB'; % Use calibrated noise files (calibrated to 0 dB)
        
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
                
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 1; % Set to 1 since we are essentially presenting '1 list'
        opts.specific.genPlaylist.Randomize = ''; % randomize playback order. 
        opts.specific.genPlaylist.Repeats = 'any'; % 
        opts.specific.genPlaylist.Append2UsedList = false; % Theres not really anything here to track, so don't worry about adding it to the used stimulus list. 
        
        % ============================
        % Player configuration
        %   The fields below are used by the designated player to configure
        %   playback.
        %
        %   - Note: some of these are set in 'Project AD' above
        % ============================
        
        % Function handle for designated player
        opts.player.player_handle = @player_main; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'none', ... % 'bytrial' means modchecks performed after each trial.
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'append_files',     false, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'standard', ... % play each file once and only once 
            'playertype',       'ptb (standard)', ... % use standard PTB playback. Streaming can introduce issues.                          '
            'mod_mixer',    fillPlaybackMixer(opts.player.playback_map, [ [1;1;0;0;0;0] [0;0;1;0;0;0] [0;0;0;1;0;0] [0;0;0;0;1;0] ] , 0), ... % play stimuli at full amplitude. They are already scaled in the files. 
            'startplaybackat',    0, ...  % start playback at beginning of files
            'contnoise',    [], ... % no continuous noise to play (for this example) 
            'wait_for_stop',    true,   ... % Wait for sound playback to end before returning control to player_main
            'state',    'run'); % Start in run state
            
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(); % Empty modcheck (don't need one here)
        
        % ============================
        % Modifier configuration        
        % ============================
        %   No modifiers for playback
        % Modifier to scale mixing information
        opts.player.modifier{end+1} = struct();  % No modifier necessary
        
        % ============================
        % Analysis        
        % ============================
        
        % Get the most recent weight estimation function
        %   This should return a time-sorted list of weight estimations for
        %   this subject. Then all we have to do is fine the one that
        %   precedes this test most recently. That's the job for a second
        %   function 
        weight_estimation = SIN_gettests(opts, 'regexp', 'Weight Estimation');
        [~, ~, weight_estimation] = sort_results_by_time(weight_estimation, 'time_reference', now); 
        
        % Error checking for weight estimation
        %   If this hasn't been done yet, then the cell array will be empty
        %   and we'll need to inform the user.
        if isempty(weight_estimation) || isempty(weight_estimation{1})
            error('No appropriate weight estimation file found. Have you run weight estimation?');
        end % if isempty ...
        
        opts.analysis = struct( ...
            'fhand',    @analysis_Hagerman, ...  % functioin handle to analysis function
            'run',  false, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function 
                'target_string', 'T', ...
                'noise_string', 'N', ...
                'inverted_string', 'inv', ...
                'original_string', 'orig', ...
                'pflag', 1, ...
                'absolute_noise_floor', '(noise floor)', ...
                'average_estimates', true, ...
                'channels', [1 2], ...
                'apply_weights',  weight_estimation{1}, ... % use the most recent weight-estimation file for this subject
                'apply_filter', true, ...
                'filter_type', 'high', ...
                'filter_order', 4, ...
                'filter_frequency_range', 125, ...
                'analysis_window',  [-30 inf], ... % use only the last 30 seconds in analyses. 
                'run_haspi',    false ... % Don't run HASPI/HASQI from the GUI. These will be incredibly slow and make it tough to run tests on the fly.
                )); 
    case 'Hagerman (Unaided, ISTS)'       
        
        % Use Hagerman (SPSHN) as a base
        opts = SIN_TestSetup('Hagerman (Unaided, SPSHN)', subjectID); 
        
        % Change test ID
        opts.specific.testID = testID; 
        
        % Change the file filter
        opts.specific.wav_regexp = 'ists;bandpass;0dB';
    
    case 'Hagerman (Aided, SPSHN)'       
        
        % Use unaided as a base
        opts = SIN_TestSetup('Hagerman (Unaided, SPSHN)', subjectID); 
        
        % Change test ID
        opts.specific.testID = testID; 
        
    case 'Hagerman (Aided, ISTS)'
        
        opts = SIN_TestSetup('Hagerman (Unaided, ISTS)', subjectID); 
        
        % Change test ID
        opts.specific.testID = testID; 
        
    case 'Weight Estimation'
        
        % This test is used to estimate the relative weights that must be
        % applied for each microphone/recording condition for Hagerman
        % style recordings. 
        
        % Use the audio timing test as a template. 
        opts = SIN_TestSetup('Audio Test (10 Hz click train)', subjectID); 
        
        % Change the test ID
        opts.specific.testID = testID; 
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'Noise');        
        
        % set a regular expression to find available lists within the HINT
        % root directory.
        %   Look for all directories beginning with "List" and ending in
        %   two digits. 
        opts.specific.list_regexp=''; 
                
        % Set regular expression for wav files
        %   Use the calibration noise file 
        opts.specific.wav_regexp = 'HINT-SPSHN;bandpass;0dB.wav';

        % Now reset genPlaylist information so it won't buck when called
        % from SIN_runTest.
        opts.specific.genPlaylist.NLists = 1; % Set to 1, we'll just use the one "list"
        opts.specific.genPlaylist.Randomize = ''; % just shuffle the lists, present stimuli in fixed order within each list.
        opts.specific.genPlaylist.Repeats = 'any'; % All lists must be used before we repeat any.         
        opts.specific.genPlaylist.Append2UsedList = false; % append list to UsedList file. We might need to create an option to remove the items from the list if an error occurs
        
        % Empty files field. Recall that the audio timing test has this
        % field populated. 
        opts.specific.genPlaylist.files = {}; 
        
        % Set the mixer to all zeros
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, [], 0);
        
        % Record mic gains. 
        cal_info = inputdlg({'Enter the gain for the LEFT microphone (Channel 1) in dB.', ...
            'Enter the gain for the RIGHT microphone (Channel 2) in dB'});
        opts.specific.cal_info.mic_gain = cal_info;
        
        % Create a test sequence to play (and record) the sound from each
        % speaker in turn.         
        for i=1:opts(1).player.playback_map.channel_number
            
            temp_opts(i) = opts; 
            
            % Remove the instructions modifier since we don't need to
            % present instructions between locations
            if i>1
                temp_opts(i).player.modifier={}; 
            end % if i>1
            
            % Set to play sound out of one speaker at a time. 
            temp_opts(i).player.mod_mixer(1,i) = 1; 
            
        end % for i=1:opts(1).player.playback.device ...
        
        % Reassign to opts
        opts = temp_opts; 
        
    case 'Sound Card Test'
        
        % This is a multi-stage validation process designed to ensure that
        % the sound card being used is adequate. These tests must be
        % conducted with an oscilloscope and requires some technical know
        % how to get done. 
        %
        % Stage 1: Matched outputs between channels
        %
        %   In most cases, it's absolutely critical to have perfectly
        %   matched outputs between all channels. More concretely, the
        %   outputs must be matched in terms of timing and output levels.
        %
        %   To do this, we will play a tone from all channels
        %   simultaneously. The user must then observe each channel pair
        %   and confirm that timing and output levels are matched. We are
        %   looking for a *point-by-point* match (with some slop due to
        %   noise in the oscilloscope itself). Precisely what the tolerance
        %   limits are will depend on the user's needs and preferences.
        %   There's no clear way to automate this. 
        %   
        % Stage 2: Channel isolation (output)
        %
        %   The next check is to make sure that when we play sound out of
        %   ONE channel that all other channels are SILENT. This is
        %   particularly important in cases when independent noise samples
        %   will be presented to each channel. 
        %
        % Stage 3: Channel isolation (input) 

        %% STAGE 1
        % Use ANL base as a starting point since we'll get continuous,
        % looped sound playback
        stage1 = SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change test ID
        stage1.specific.testID = testID; 
        
        % Change the stimulus directory, wav filter, and task instructions.
        stage1.specific.root = fullfile(stage1.general.root, 'playback', 'calibration'); 
        stage1.specific.wav_regexp = '1kHz_tone.wav'; 
        
        % Change the mixer so we pipe the calibration tone to all channels
        % simultaneously.        
        stage1.player.mod_mixer = fillPlaybackMixer(stage1.player.playback_map, 0.5.*ones(1,4), 0);
        
        % We don't need to record, so set flag to false
        stage1.player.record_mic = false; 
        
        % Change instructions and title
        stage1.player.modcheck.instructions = fileread(fullfile(stage1.general.instruction_dir, 'soundcard_test_stage_01.txt')); 
        stage1.player.modcheck.title = [testID ': Stage 01']; 
        
        %% STAGE 2

        % Change mixer
        for i=1:stage1.player.playback_map.channel_number
            
            % Copy stage1 as a scaffold 
            if ~exist('stage2', 'var')
                stage2 = stage1;
            else
                stage2(end+1) = stage1; 
            end 
            
            % Change instructions and title
            stage2(end).player.modcheck.instructions = fileread(fullfile(stage1.general.instruction_dir, 'soundcard_test_stage_02.txt')); 
            stage2(end).player.modcheck.title = [testID ': Stage 02 : Channel ' num2str(i)]; 
            
            % Reset mixer to zeros
            mixer = zeros(1, stage1.player.playback_map.channel_number); 
            mixer(i) = 0.5; 
            stage2(end).player.mod_mixer = fillPlaybackMixer(stage2(end).player.playback_map, mixer, 0) ;
            
        end % for i=1:stage1 ...
        
        % Create options structure
        opts = [stage1, stage2]; 
        
    case 'Play and Record Sound (from file)'   
        
        % This is a basic scenario that allows the user to playback and
        % record a file or files. 
        
        % Start with HINT since this is basically what we want to do. Will
        % need to remove modifiers and modchecks.
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID); 
        
        % Just use roving phase - should give us what we need.
        opts = opts(1); 
        
        % Replace test ID
        opts.specific.testID = testID; 
        
        % Remove modcheck and modifier
        opts.player.modcheck = {};
        opts.player.modifier = {}; 
        
        % Get the files to play
        [playback_files, PathName, FilterIndex] = uigetfile(fullfile('playback', '.wav'), 'Multiselect', 'on');
        
        % Append pathname to all files
        if iscell(playback_files)
            n_files = numel(playback_files);
        else
            n_files = size(playback_files,1);
        end % 
        
        for i=1:n_files
            if iscell(playback_files)
                playback_files{i} = fullfile(PathName, playback_files{i}); 
            else
                playback_files = {fullfile(PathName, playback_files)}; 
            end 
        end % for i=1:numel ...
        
        % Remove lists from genPlaylist
        opts.specific.genPlaylist.lists = {}; 
        
        % Replace files for playback
        opts.specific.genPlaylist.files = playback_files; 
        clear playback_files PathName FilterIndex; 
        
        % Estimate the mixer
        %   For now, this will simply map each channel in order to the
        %   corresponding speaker number. So data channel 1 goes to speaker
        %   1, 2 to 2, and so on.
        
        % Load the first file to determine the data size
        data = SIN_loaddata(opts.specific.genPlaylist.files{1}); 
        
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, eye(size(data, 2)) , 0); % play stimuli at full amplitude. They are already scaled in the files.         
       
        % Wait for stop of playback
        opts.player.wait_for_stop = true; 
    
    case '[Project AD] Hagerman (from file)' 
        
        % Start with HINT since this is basically what we want to do. Will
        % need to remove modifiers and modchecks.
        opts = SIN_TestSetup('Play and Record Sound (from file)', subjectID); 
        
        % Just use roving phase - should give us what we need.
        opts = opts(1); 
        
        % Replace test ID
        opts.specific.testID = testID; 
        
        % Change mixer
        opts.player.mod_mixer = fillPlaybackMixer(opts.player.playback_map, [ [1;1;0;0;0;0] [0;0;1;0;0;0] [0;0;0;1;0;0] [0;0;0;0;1;0] ] , 0);
        
        % Add the analysis from hagerman, whatever it currently is
        hag = SIN_TestSetup('Hagerman (Unaided, SPSHN)', subjectID);         
        opts.analysis = hag.analysis; 
        
    
        
    case 'HINT (First Correct)'
        
        % This is the first segment in HINT testing during which we present
        % the same stimulus repeatedly until the listener understands it
        % completely. 
        
        % Start with HINT (SNR-50 ... for starters
        opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', subjectID);
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Add a modifier to stop playback after the first correct response
        % is recorded (that's 100% of scored words repeated correctly).
        opts.player.modifier{end + 1} = struct( ...
            'fhandle',  @modifier_exitAfter, ... % 
            'mod_stage',    'premix',  ...  % apply modifications prior to mixing
            'expression',   'mod_code == -1');         

        % Find scaling modifier. Once found, fix dBsteps to 4 dB
        ind = getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_dBscale_mixer);
        opts.player.modifier{ind}.dBstep = 4; 
        opts.player.modifier{ind}.change_step = 1; 
        
        % Get a file list
        opts.specific.genPlaylist.NLists = 1;
        opts.specific.genPlaylist.Randomize = '';
        opts.specific.genPlaylist.Repeats = 'any';
        opts.specific.genPlaylist.Append2UsedList = false;         
        playlist = SIN_getPlaylist(opts); 
        
        % Always use the same sentence for the exploratory part
        opts.specific.genPlaylist.files = repmat({playlist{1}}, 20,1);
        
        % Now add an aribtrarily large number of trials. This should be an
        % upper bound on the number of trials that are presented during
        % this test segment.
        
        
        % Set NLists to 0 now or the next call to SIN_getPlaylist will
        % crash
        opts.specific.genPlaylist.NLists = 0;
    
    case 'ANL (MCL-Too Loud)'
        % ANL (MCL-Too Loud) is the first step in the ANL sequence. The
        % listener is instructed to adjust the speech track until it is too
        % loud. 
        
        % Get base
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID;
                       
        % Set mixer
%         opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [db2amp(+10); 0 ] [0; 0]], 0); % just discourse in first channel 
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [db2amp(-15); 0 ] [0; 0]], 0); % just discourse in first channel 
%         opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [0.2.*ones(2, 8)], 0); % just discourse in first channel 
        
    case 'ANL (MCL-Too Quiet)'
        
        % This is just like the ANL (base), but with different
        % instructions and a different starting buffer position.
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID = testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            ['Experimenter: The subject will now use his/her thumb to make the speech too quiet.']};
        
        % Set mixer
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [1; 0] [0; 0 ] ], 0); % just discourse in first channel 
        
    case 'ANL (MCL-Estimate)' 
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Experimenter: the subject will now use his/her thumbs to the most comfortable level.'};           
        
        % Change step size to 2 dB
        %   First, find the dBscale mixer modifier
        ind = getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_dBscale_mixer);
        opts.player.modifier{ind}.dBstep = 2; 
        clear ind; 
        
        % Set mixer
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [1; 0] [0; 0 ] ], 0); % just discourse in first channel 
        
    case 'ANL (BNL-Too Loud)'
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            ['Experimenter: Provide instructions under "Administer BACKGROUND NOISE LEVEL (BNL)" in protocol. ' ...
                'The subject will now use his/her thumb to make the background noise too loud.']};           
        
        opts.player.modifier{2}.data_channels=2; 
        
        % Set mixer
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [0; db2amp(-15)] [0; 0 ] ], 0); % discourse channel and babble to first channel only
        
    case 'ANL (BNL-Too Quiet)' 
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            ['Experimenter: The subject will now use his/her thumb to make the background noise too quiet.']};
        
        opts.player.modifier{2}.data_channels=2; 
        
        % Set mixer
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [1; 1] [0; 0 ] ], 0); % discourse channel and babble to first channel only       
        
    case 'ANL (BNL-Estimate)'
        
        opts=SIN_TestSetup('ANL (base)', subjectID); 
        
        % Change testID
        opts.specific.testID=testID; 
        
        % Change instructions
        opts.player.modcheck.instructions={...
            'Experimenter: the subject will now use his/her thumbs to the maximum tolerable noise level.'};           
        
        % Change step size to 2 dB
        %   First, find the dBscale mixer modifier
        ind = getMatchingStruct(opts.player.modifier, 'fhandle', @modifier_dBscale_mixer);
        opts.player.modifier{ind}.dBstep = 2; 
        opts.player.modifier{ind}.data_channels=2; 
        clear ind; 
        
        % Set mixer
        opts.player.mod_mixer=fillPlaybackMixer(opts.player.playback_map, [ [1; 1] [0; 0 ] ], 0); % discourse channel and babble to first channel only        
    
    case 'ANL (base)' % base settings for sequence of tests comprising ANL
        % ANL is administered differently than HINT or PPT. Here's a
        % very basic breakdown of the procedure.
        %
        %   Stage 1: Establishing the most comfortable level (MCL)
        %
        %       1. Start story at 30 dB HL (~50 dB SPL). 
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
        opts.specific.list_regexp = ''; 
        opts.specific.wav_regexp='ANL;bandpass;0dB.wav'; 
        
        % The following set of subfields are required for playlist
        % generation. They are used in a call to SIN_getPlaylist, which in
        % turn invokes SIN_stiminfo and other supportive functions.         
        opts.specific.genPlaylist.NLists = 1; % Has to be set to 1 in order to work with SIN_getPlaylist. We're just playing a single item "list"
        opts.specific.genPlaylist.Randomize = 'any'; % No stimuli to randomize
        opts.specific.genPlaylist.Repeats = 'any'; % irrelevant since there aren't any lists        
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
        opts.player.player_handle = @player_main; 
        
        opts.player = varargin2struct( ...
            opts.player, ...
            'adaptive_mode',    'continuous', ... % 'continuous' adaptive playback
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'append_files',     true, ...  % append files before playback (makes one long trial)
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
            'playback_mode',    'looped', ... % loop sound playback - so the same sound just keeps playing over and over again until the player exits
            'playertype',       'ptb (stream)', ... % use streaming playback mode 
            'startplaybackat',    0, ...  % start playback at beginning of sound 
            'mod_mixer',    fillPlaybackMixer(opts.player.playback_map, [ [0;0] [0;0] [1;1] [0;0] ], 0), ... % Play both channels to left ear only. 
            'contnoise',    '',     ... % no continuous noise playback. This option only relevent for MLST (usually)            
            'state',    'pause'); % start in paused state
        
        % ============================
        % Modification check (modcheck) configuration        
        % ============================
        opts.player.modcheck=struct(...
            'fhandle',  @modcheck_ANLGUI, ...     % check for specific key presses
            'instructions', {{['Experimenter: Provide instructions under "Administer MOST COMFORTABLE LEVEL (MCL)" in protocol. ' ...
                'The subject will now use his/her thumb to make the speech too loud.']}}, ...                
            'keys',     [KbName('i') KbName('j') KbName('p') KbName('q') KbName('r')], ...  % first key makes sounds louder, second makes sounds quieter, third for pause, fourth for quit, fifth for run             
            'map',      zeros(256,1), ...
            'title', 'Acceptable Noise Level (ANL)');

        % Assign keys in map
        %   CWB isn't sure this has an actual function. 
        opts.player.modcheck.map(opts.player.modcheck.keys)=1; 
        
        % ============================
        % Modifier configuration                
        % ============================
        % Add the modifier for playback control
        %   Needed to start/stop/pause playback during testing 
        opts.player.modifier{end+1} = struct( ...
            'fhandle', @modifier_PlaybackControl, ...
            'mod_stage',    'premix');  % Apply during premixing phase. 
            
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
        
        % ============================
        % Analysis Configuration               
        % ============================
        opts.analysis = struct( ...
            'fhand',    @analysis_ANL, ...  % functioin handle to analysis function
            'run',  true, ... % bool, if set, analysis is run from SIN_runTest after test is complete.
            'params',   struct(...  % parameter list for analysis function (analysis_ANL)
                'order',    1:6, ...
                'tmask',    logical(fillPlaybackMixer(opts.player.playback_map, [1;0], 0)), ...   % just get data/physical channel 1
                'nmask',    logical(fillPlaybackMixer(opts.player.playback_map, [0;1], 0)), ...   % get data chan 2/phys chan 1
                'plot', 1)); % generate summary plots only
            
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
%
%   For multi-part tests, use the same UUID and the same saveData2mat file.
%
%   CWB decided that the format described above was WAY too confusing to
%   look at, so went back to original format. 
for i=1:length(opts)
    opts(i).specific.saveData2mat = fullfile(opts(1).subject.subjectDir, [opts(1).subject.subjectID '-' testID ' (' opts(1).specific.uuid ')']);
end %
