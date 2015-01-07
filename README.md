Speech In Noise (SIN) Software Package
===

Overview
--------

SIN is a software package that has been used to run many behavioral tests, including basic psychoacoustic and highly demanding audiological paradigms, at multiple testing sites and Univerisities. For example, SIN has been used to do everything from basic playback and recording to administering audiovisual clinical tests like the Multimodal Lexical Sentence Test (MLST) developed by Karen Kirk and colleagues at the University of Iowa (http://www.flintbox.com/public/project/23463). 

The package is written primarily in MATLAB and leverages PsychToolBox (http://psychtoolbox.org/) to create a uniform testing environment with virtually any hardware setup. 

Why Use SIN?
------

Motivation and Development Goals
------

SIN was initially developed for a multi-site project between the University of Washington and University of Iowa. The project required experimenters to administer approximately 30 - 40 individual audio or audiovisual tasks in a highly reproducible way with minimal inter-experimenter variance across 250 patients. While there are procedures and, in rare instances, applications to administer individual tests, many of these procedures require the experimenter to make real-time decisions and manual adjustments; thus, mistakes are likely, difficult to recover from, and, more importantly, often go unnoticed. In our specific application, it would approximately 500 unique decision points for each participant. That's 500 potential mistakes that would be untraceable and uncorrectable using established procedures.

Thus, the goal SIN was to create a flexible and uniform platform upon which all tests could be administered, scored, and stored with minimal experimenter input.

Design
------

_Front End_

As mentioned above, one of my primary goals in writing SIN was to create something that is easy to use for experimenters of all shapes, sizes, ages, and abilities. While I generally prefer command-line work and batch scripting for analyses, this specific application required an easy-to-use GUI based front end.

For most experimenters, **runSIN.m** is the only function you'll ever need to invoke explicitly. This will launch a simple GUI outfitted with all the functionality you need to register new subjects, run tests, explore results, run analyses, etc. 

A detailed walkthrough of the GUI is forthcoming. For immediate questions, please e-mail me directly as this will help shape the walkthrough.

_Under the Hood_

SIN is comprised of four major types of functions:

1. _Players_
  + A player generally accepts a set of stimuli and parameters to configure playback, recording, modification checks, modifiers, etc. 
2. _Modification Checks_
  + Modification checks are generally used to gather some form of information and convert that information into a set of discrete actions. For example, a mod check may send a actionable modification code to one or more modifiers in response to a button press.
3. _Modifiers_
  + Modifiers can modify anything about the player, player parameters, or the playback/recording data.
  + Modifiers typically wait for a specific modification code before taking an action. For instance, the up-and-coming playback signal may be scaled in response to experimenter pressing a "louder" button during the mod check stage.
  + Other modifiers may provide their own conditional checks and determine actionable events in lieu of a modification check. In these cases, there is little difference between a modification check and a modifier except perhaps when and how it is executed within the player
4. _Analyses_
  + Analyses accept the returned data structure(s) from a player and analyze the data in some way. The nature of the analysis will depend on the experimenter's desired metrics. 
 
In addition to these, SIN comes packaged with many higher-level functions for test control, subject creation, data handling, etc. 

_Why mod checks and mofifiers?_

The decision to use a two-step modification procedure was made to allow users to mix and match test behaviors more easily. For example, the HINT scoring GUI and accompanying modification check were recycled with the MLST. The only difference between the two tests is the player parameters and the modifiers employed. 

Installation Dependencies
------

Step-by-step installation instructions of all core SIN software and dependencies are available at the link below. If you have any difficulty with insallation, please contact Chris Bishop at cwbishop@uw.edu.

http://www.evernote.com/l/AWGfHzxf2PNGJ6j1YIb7q57vsgzQtCPZ56c/

Available Tests
------

Currently, there are 48 individual tests or test segments designed and vetted in SIN. However, all of these tests fall into the following major categories. For a detailed description of each, please see SIN_TestSetup.m.

1. _Hearing in Noise Test (HINT)_
2. _Multimodal Lexical Sentence Test (MLST)_
3. _Reading Span_
4. _Word Span_
5. _Acceptable Noise Level_
6. _Hagerman-Style Phase-Inversion Recordings_

Developing New Tests
------

To illustrate a typical development work flow for a new test, consider the (abbreviated) development of the Hearing in Noise Test (HINT)

- Create a GUI that can be used to score each sentence of the HINT (see HINT_GUI)
- Create a mod check that calls the GUI and uses its output to decide if any actionable event is required (e.g., increase the SNR on the subsequent trial). See modcheck_HINT_GUI
- Create a modifier to implement the designed modification. In this case, modifier_dBscale_mixer changes the mixing matrix to alter the SNR in the next trial.
- Select a playback list. In this case, the playback list is one or more HINT lists. 
- After all items in the playback list have been presented, analyze the data using an analysis script. See analysis_HINT. 

Function List
------

|Function | Description|
|---------|------------|
|addnoise2HINT.m| |
|algo_HINT1up1down.m| |
|algo_HINT3down1up.m| |
|algo_HINT4down1up.m| |
|algo_HINTnochange.m| |
|algo_NALadaptive.m| |
|algo_staircase.m| |
|align_timeseries.m| |
|amp2db.m| |
|analysis_ANL.m| |
|analysis_AudioTest.m| |
|analysis_Hagerman.m| |
|analysis_HINT.m| |
|analysis_MLST.m| |
|analysis_weight_estimation.m| |
|analysis_WordSpan.m| |
|ANL_GUI.m | |
|ANL_modcheck_keypress.m | |
|aw_rms.m| |
|calcBandSNR_v2.m| |
|class2txt.m | |
|color2colormap.m| |
|comp_struct.m| |
|concat_and_match_spectra.m| |
|concat_audio_files.m| |
|concatenate_lists.m| |
|create_signaltag.m| |
|create_wordspan_lookup.m| |
|createHagerman.m| |
|createHINTlookup.m| |
|createMLSTlookup.m| |
|db2amp.m| |
|erplab_linespec.m| |
|fade.m| |
|fftplot.m| |
|fillPlaybackMixer.m| |
|filter_table.m| |
|filterA.m| |
|findcell.m| |
|getCases.m| |
|getMatchingStruct.m| |
|git_is_current.m| |
|git_sha.m| |
|Hagerman_find_weight_estimation.m| |
|Hagerman_getsignal.m| |
|Hagerman_record.m| |
|HINT_chooseAlgo.m| |
|HINT_GUI.m| |
|HINT_score2binary.m| |
|importHINT.m| |
|Instructions.m| |
|is_reversal.m| |
|iseegstruct.m| |
|iserpstruct.m| |
|label_datapoint.m| |
|lineplot2d.m| |
|load_lookup_table.m| |
|make_stimuli.m| |
|map_channels.m| |
|match_spectra.m| |
|mex_uuid.m| |
|mixer2pan.m| |
|MLST_makemono.m| |
|modcheck_ANLGUI.m| |
|modcheck_HINT_GIU.m| |
|modcheck_wordspan_gui.m| |
|modifier_append2playlist.m| |
|modifier_dBscale_mixer.m| |
|modifier_exit_after.m| |
|modifier_exit_after_nreversals.m| |
|modifier_exit_trials.m| |
|modifier_exitAfter.m| |
|modifier_instructions_by_trial.m| |
|modifier_NALscale_mixer.m| |
|modifier_PlaybackControl.m| |
|modifier_ShowInstructions.m| |
|modifier_trackMixer.m| |
|player_main.m| |
|plot_psd.m| |
|plot_waveform.m| |
|portaudio_GetDevice.m| |
|recordings_to_file.m| |
|regexpdir.m| |
|remixaudio.m| |
|runSIN.m| |
|Selection_GUI.m| |
|sem| |
|SIN_assignUUID.m| |
|SIN_CalAudio.m| |
|SIN_ClearErrors.m| |
|sin_gen.m| |
|SIN_getPlaylist.m| |
|SIN_getsubjects.m| |
|SIN_gettests.m| |
|SIN_keywords.m| |
|SIN_load_results.m| |
|SIN_loaddata.m| |
|SIN_makeFilter.m| (not used)|
|SIN_maskdomain.m| |
|SIN_matchspectra.m| (use match_spectra.m instead)|
|SIN_recoverDevice.m| |
|SIN_register_subject.m| |
|SIN_removepunctuation.m| |
|SIN_review_recordings.m| |
|SIN_runAnalysis.m| |
|SIN_runsyscmd.m| |
|SIN_runTest.m| |
|SIN_saveRestuls.m| |
|SIN_select.m| |
|SIN_stiminfo.m| |
|SIN_TestSetup.m| |
|SIN_UsedListInfo.m| |
|sort_results_by_time.m| |
|struct2keyval.m| |
|threshclipaudio.m| |
|timestamps.m| |
|update_results.m| |
|uuidgen.m| |
|uuidgen_cimp.cpp| |
|uuidgen_cimp.mexa64| |
|uuidgen_cimp.mexglx| |
|uuidgen_cimp.mexw32| |
|varargin2struct.m| |
|wordspan_find_keywords.m| |
|wordspan_rename_files.m| |
|WordSpan_Scoring.m| |




_Core_



_Stimulus Generation_
|Function | Description|
|addnoise2HINT.m | |

_Stimulus Calibration_
|Function | Description|

_Modification Checks_
|Function | Description|

_Modifiers_
|Function | Description|

_Analysis_
|Function | Description| 

_Signal Processing_
|Function | Description|

_Behavioral Algorithms_
|Function | Description|
|algo_HINT1up1down.m | |
_Other_
