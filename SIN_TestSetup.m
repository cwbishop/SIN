function opts=SIN_TestSetup(testID)
%
% Should also spit back a testlist. This is needed for SIN_GUI
opts=struct();

switch testID
    
    case 'empty'
        
        % Create an empty SIN testing structure
        opts = struct( ...
            'general', struct(), ... % general information
            'specific', struct(), ... % test specific parameters (used by auxiliary functions like modchecks/modifiers/GUIs
            'player', struct(), ... % player configuration structure (e.g., for portaudio_adaptiveplay)
            'sandbox', struct());  % scratch pad for passing saved variables between different functions (e.g., data to plot, figure handles, etc.)
        
    case 'Project AD'
        
        % Get an empty structure
        opts=SIN_TestSetup('empty'); 
        
        % Set some default values, like device settings, that will be used
        % by multiple tests. 
        
        % Root SIN directory
        opts.general.root='C:\Users\cwbishop\Documents\GitHub\SIN';
        % subject ID motif. Described using regexp. Used in
        % SIN_register_subject.m
        opts.general.subjectID_regexp='^[1 2][0-9]{3}$';
        
        % List of available tests
        %   This will vary by project. Field used to generate test list in
        %   SIN_GUI. CWB does not recall using it elsewhere. 
        opts.general.testlist = {{'HINT (SNR-50)', 'PPT', 'ANL', 'Hagerman'}}; 
        
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
        
    case 'HINT (SNR-50)'
        
        % ============================
        % Get default information
        % ============================
        opts=SIN_TestSetup('Project AD');
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID='HINT (SNR-50)';
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'HINT');
        
        % full path to HINT lookup list. Currently an XLSX file provided by
        % Wu. Used by importHINT.m
        opts.specific.hint_lookup=struct(...
            'filename', 'C:\Users\cwbishop\Documents\GitHub\SIN\playback\HINT\HINT.xlsx', ...
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
        opts.player.modifier{1}=struct( ...
            'fhandle',  @modifier_dBscale, ... % use a decibel scale
            'dBstep',   [4 2], ...  % decibel step size (4 dB, then 2 dB)
            'change_step', [1 5], ...   % trial on which to change the step size
            'channels', 2, ...  % apply modification to channel 2
            'scale_mode',   'cumulative'); % use cumulative scale mode.             
            
    case 'ANL'
        
        % Test setup for the Acceptable Noise Level (ANL) Test
        % ============================
        % Get default information
        % ============================
        opts=SIN_TestSetup('Project AD');
        
        % ============================
        % Test specific information. These arguments are used by
        % test-specific auxiliary functions, like importHINT and the like. 
        % ============================
        
        % set the testID (required)
        opts.specific.testID='ANL';
        
        % root directory for HINT stimuli and lookup list
        opts.specific.root=fullfile(opts.general.root, 'playback', 'ANL');
              
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
            'adaptive_mode',    'continuous', ... % 'continuous' adaptive playback
            'record_mic',       true, ...   % record playback and vocal responses via recording device. 
            'randomize',        false, ...   % randomize trial order before playback
            'append_files',     true, ...  % append files before playback (makes one long trial)
            'playback_channels',[1 2], ...  % channels to present sounds to. 
            'window_fhandle',   @hann, ...  % windowing function handle (see 'window.m' for more options)
            'window_dur',       0.005, ...  % window duration in seconds.
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
            'keys',     [KbName('left') KbName('right')], ...  % first key makes sounds louder, second makes sounds quieter
            'map',      zeros(256,1));
        
        % Assign keys in map
        opts.player.modcheck.map(opts.player.modcheck.keys)=1; 
        
        % ============================
        % Modifier configuration        
        %   We use two modifiers, but CWB can't recall why. Need to check
        %   this. 
        % ============================
        opts.player.modifier{1}=struct( ...
            'fhandle',  @modifier_dBscale, ... % use a decibel scale
            'dBstep',   1, ...  % use constant 1 dB steps
            'change_step', 1, ...   % always 1 dB
            'channels', 2, ...  % apply modification to channel 2
            'scale_mode',   'immediate'); % use immediate (no history) scaling
            
    otherwise
        
        error('unknown testID')
        
end % switch 

