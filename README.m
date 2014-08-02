=======================================================================================================
Test Setup -> What the user has to provide to get the player functions to work. Options structures can be tailored to each player. The example below configures the portaudio_adaptiveplay function to administer the HINT. 

    -> Subject information (subject): information about the subject 
        -> subjectID : the subject identifier
        -> subjectDir: directory where subject data (and other information) is stored
        
	-> General settings (general): Generally static information across an experiment (e.g., subject ID motif, etc.)
		-> root: root directory for speech in noise (SIN) suite (required)		
		
	-> Test specific args (specific): parameters may vary, but some fields are required (e.g., testID). Example below is for the HINT. 
		-> testID: string with description test ID. (required)
		-> root: path to root directory where test specific materials are stored. 
		-> subjectID_regexp: regular expression describing subject ID motif. 
        -> list_filt (rename to list_regexp): regular expression to use in finding available list (for HINT, this is done by looking up available directories following the regexp 'List[0-9]{2}') (used by SIN_GUI)
		-> hint_lookup: information about lookup list containing word information, list IDs, etc.
            -> filename: full path to the file containing list information (used by importHINT)
			-> sheetnum: For Excel spreadsheets, we need to know which sheet to load - here, we load sheet two (2) (used by importHINT)            
		-> genPlaylist: fields required by SIN_getPlaylist to generate a playlist. For more information on these fields (and perhaps omitted fields), see help SIN_getPlaylist.
            -> NLists: number of lists to include in playlist
            -> Randomize: Randomization scheme (not implemented fully)
            -> Repeats: rule governing how repeats are handled
            -> UsedList: path to mat file containing UsedList. 
            
        -> saveData2mat:    This is used by SIN_saveResults to write the output of HINT (and other) tests to file. This is the path to the mat file where data should be saved. 
        
	-> Player settings (player): Options used by the designated player (example for portaudio_adaptiveplay).
		
		-> player_handle: function handle to player (e.g., @portaudio_adaptiveplay) (required) This might be used by SIN_RunTest to administer tests by ID)
		
		-> Playback (Playback Parameters)			
			-> block_dur: buffer block duration in seconds
			-> device: playback device structure returned from portaudio_GetDevice
			-> fs: sampling rate
		
		-> Record (Recording parameters, if applicable)
			-> device: recording device
			-> fs: sampling rate
			-> buffer_dur: recording buffer duration (in sec)
		
        (Player Configuration)
		-> adaptive_mode:
        -> playback_mode: (looped | standard)
		-> append_files: 
        -> stop_if_error:
		-> playback_channels: XXX Removed and replaced with channel_mixer
		-> randomize: randomize playback list. This is currently handled in SIN_runTest, but I think it would be smarter to move this centralize playback features like this to the "player" (e.g., portaudio_adaptiveplay)
        -> startplaybackat: when to start playback within a sound. This parameter is useful when the user wants to start playback at an arbitrary point within a file. To start at the beginning of the file, set to 0. (no default)
        -> channel_mixer: 
        -> state: state of the player upon startup
        
		(Buffer Windowing)
		-> window_fhandle: windowing function handle
		-> window_dur: duration of windowing function in seconds
		
		(Unmodulated playback parameters : used to present constant noise on each trial or throughout playback
		-> unmod_playback: single element cell, full path to wav file
		-> unmod_channels: 
		-> unmod_playbackmode: 
		-> unmod_leadtime:
		-> unmod_lagtime: 
		
		(Modification Check: information will vary, example below for HINT_modcheck_GUI.m)
		-> modcheck
            -> fhandle: function handle
			-> playback_list: XXX this one could be a problem XXX XXX Not if we add the playback_list to the results structure and pass that around XXX
			-> scoring_method: 
			-> score_labels: 
		
		(Modifier): modifier information: setting will vary example below for modifier_dBscale)
		-> modifier
			-> dBstep: 
			-> change_step: 
			-> channels: 			
            
            (required fields)
            -> fhandle: function handle for modifier
            -> mod_stage:   string describing when modifier should be run within a given player. These are only relevant for the "continuous" adaptive mode, I think. 
                -> 'premix': apply prior to mixing. Useful for data_channel specific modifications, like scaling individual channels
                -> 'postmix': apply after mixing, prior to sound playback
    -> Sandbox: a dirty area where variables can be stored if necessary and accessed by different functions (e.g., figure or axis information for plotting, etc).
    
    -> Calibration info (calibration): calibration information is provided here. This will mirror the "calibration" structure below exactly, whatever that ends up being.    
    
                
=======================================================================================================
Results Structure: Player return structure. This contains three basic fields
	-> User Options (UserOptions) (options provided by user, see Options structure above). This field can be used to relaunch the same test with the same settings (although playback order might change). 
	-> RunTime: modified (and appended) options structure. This may contain additional fields not present in User Options. The fields will vary by player type. Example below for portaudio_adaptiveplay. Only additional top-level fields are desribed below.
		-> playback_list: cell array of playback files
		-> voice_recording: cell array of recorded responses if the player is configured to record subject responses through the recording device (see Record field above). (should be added at end of playback, I think, to keep structure size down)

=======================================================================================================
Calibration info (specific): specific field for calibration routine 
    -> root: root file for calibration. This is the directory that calibration files are located. SIN_HOME/calibration/YOUR_CALIBRATION/thecalfile
    -> output_root: where the next executed calibration will be stored, including the root file name. The filename will be appended with other information regarding physical_channel information and the like
    -> physical_channels: integer array, physical channels to calibrate
    -> calstimDir: the directory in which the calibration stimulus is located
    -> calstim_regexp: regular expression for selecting calibration stimulus from calstimDir
    -> reference:
        -> absoluteSPL: decibel level of calibration tone (e.g., 114 dB)
        -> rectime: (approximate) recording time for reference sound.     
    -> matchspectra: settings needed to match spectra between channels
        -> mtype: match type. (use 'power' and only 'power')
        -> plev: true, creates plots for visualization
        -> frange: frequency range over which we want to match the spectra (and levels)
        -> window: window duration for spectral estimation (sec)
        -> noverlap: just use [];        
        -> write: set to false. We don't want these files written anywhere        
        
        Note: nfft is determined in SIN_calibrate - this is not something the user can specify at this point since it's easy to screw things up. 
        
    -> instructions: a field with instruction information for various stages of the calibration process
        -> noise_estimation:   instructions during noise estimation. This is a recording with no (externally generated) sound input. No calibrator, no speakers being explicitly driven. This will serve as a baseline to which SNR can be estimated
        -> reference: instructions during reference recording
        -> playback: instructions to display during driver (e.g., speaker/earphone) calibration
    -> record_channels: integer, the recording channel to use in calibration. This is often necessary if a device has multiple record_channels (e.g., stereo recording)     
    -> match2channel: channel to which all other physical channels are matched. 

=======================================================================================================
Calibration Filters(CalFilters): This structure describes the calibration filters, as estimated using SIN_calibrate
    -> fs
    -> 
    