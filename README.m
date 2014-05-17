=======================================================================================================
Test Setup -> What the user has to provide to get the player functions to work. Options structures can be tailored to each player. The example below configures the portaudio_adaptiveplay function to administer the HINT. 

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
		-> append_files: 
		-> stop_if_error:
		-> looped_playback (not implemented):
		-> playback_channels:
		-> randomize: (not implemented) randomize playback list. This is currently handled in SIN_runTest, but I think it would be smarter to move this centralize playback features like this to the "player" (e.g., portaudio_adaptiveplay)

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
			-> scale_mode: 
            
    -> Sandbox: a dirty area where variables can be stored if necessary and accessed by different functions (e.g., figure or axis information for plotting, etc).
    
=======================================================================================================
Results Structure: Player return structure. This contains three basic fields
	-> User Options (UserOptions) (options provided by user, see Options structure above). This field can be used to relaunch the same test with the same settings (although playback order might change). 
	-> RunTime: modified (and appended) options structure. This may contain additional fields not present in User Options. The fields will vary by player type. Example below for portaudio_adaptiveplay. Only additional top-level fields are desribed below.
		-> playback_list: cell array of playback files
		-> voice_recording: cell array of recorded responses if the player is configured to record subject responses through the recording device (see Record field above). (should be added at end of playback, I think, to keep structure size down)