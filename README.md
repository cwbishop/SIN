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
7. _System Calibration_
  + Weight Estimation: used to estimate the relative power levels between each speaker (or other audio driver) and recording channel. If two microphones are positioned in a listener's ear canals, then this is approximately equivalent to a binaural room impulse response (BRIR) collapsed across time and frequency. 

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

_Core SIN Functions_ 

|Function | Description/Notes|
|---------|------------|
|addnoise2HINT.m|Function to add noise to HINT stimuli. User must provide a wav file with the noise. Assumes HINT stimuli are in the ../playback/HINT directory (hard coded for ease).|
|algo_HINT1up1down.m| Function to generate 1 up 1 down algorithm behavior for Hearing in Noise Test (HINT). This is essentially a wrapper for algo_staircase, which makes the actual decisions. algo_HINT1up1down just massages the   'score' returned by modcheck_HINT_GUI into an appropriate format and creates a (hard-coded) decision matrix for use with algo_staircase.|
|algo_HINT3down1up.m| Similar to algo_HINT1up1down.m, but with three-down-one-up staircase.|
|algo_HINT4down1up.m| Similar to algo_HINT1up1down.m, but with four-down-one-up staircase.|
|algo_HINTnochange.m| Placeholder algorithm that simply returns a mod_code of 0.|
|algo_NALadaptive.m| Not used by SIN any longer. This should be written in OOP fashion rather than using persistent variables. Simultaneous and parallel tracking algorithms are not possible as written. |
|algo_staircase.m| his is the core control for all stair case algorithms (e.g., 1up1down, 4down1up, etc.) in the SIN package. In order to remain flexible, it uses a "decision matrix" (see below) to provide instructions on what should be done on the next trial. Although this function controls the key decision making portions of staircase algorithms, it does *not* invoke any changed directly. Rather, it provides a general set of instructions through the decision matrix that can be interpreted in other functions.|
|align_timeseries.m|Function to align time series using one of several realignment strategies. If the signal in Y occurs before the signal in X, then Y is delayed to match Y. If the signal in X occurs before the signal in Y, then X is delayed to match X. Both time series are zero padded after realignment (either prepended zeros or appended zeros depending on the direction of the shift) so signal lengths match after realignment. |
|amp2db.m| Convert amplitude to decibel scale. |
|analysis_ANL.m| Analysis function for ANL testing. |
|analysis_AudioTest.m|Analysis function for AudioTest. |
|analysis_Hagerman.m| Analysis function for Hagmeran. This is still being actively developed and tested, particularly with respect to attenuation estimation.|
|analysis_HINT.m| Analysis for HINT-like tests. Includes several scoring schemes (traditional, reversals, etc.)|
|analysis_MLST.m| Analysis for MLST. |
|analysis_weight_estimation.m|Analysis for weight estimation tests. |
|analysis_WordSpan.m| Analysis for word span.|
|ANL_GUI.m | A GUI used to administer the ANL. This is also used by several other tests that are not strictly ANL. |
|ANL_modcheck_keypress.m | Early version of modcheck for ANL. No longer used. |
|_aw_rms_.m| Calculates A-weighted RMS. This function is borrowed from elsewhere. |
|calcBandSNR_v2.m| Donated by James Lewis.|
|class2txt.m | convert various classes to a descriptive text string. Designed to be used in combination with Selection_GUI and SIN_select.|
|color2colormap.m| Simple lookup table to create a colormap from typical 'color' values from plot, etc. (e.g., 'r', 'b', 'k', ...). This proved useful when creating bar plots that follow the same color scheme as ERPLAB's plotting functions.|
|comp_struct.m| Compare two structures. Borrowed from MATLAB file exchange.|
|concat_and_match_spectra.m| No longer used since it implicitly calls SIN_matchspectra, which has been replaced by match_spectra.m|
|concat_audio_files.m|This function will load and concatenate all audio files. Parameters below apply some control over stimulus processing (e.g., trimming silence from beginning and end of sound, etc.).|
|concatenate_lists.m| This function converts a LIST x N cell array to a (LIST x N) x 1 cell array. This proved useful when converting the output from SIN_stiminfo to a single file list.|
|create_signaltag.m|  Function to create a repetitive train of a given signal with a specified SOA. Originally written for use with Hagerman-style recordings.|
|create_wordspan_lookup.m| Creates an XLSX lookup table to be used with SIN.|
|createHagerman.m| Function to create stimuli for Hagerman recordings. The basic idea is to provide a method of estimating SNR, a flag for holding the noise or speech track constant, and a naming scheme to use to save the output files. Hagerman stimuli for Project AD: HA SNR are comprised of ~1 minute of concat_target_trackenated HINT sentences (e.g., List01 - List03) paired with one of several noise types (speech-shaped noise (SSN) and ISTS). Other flags provide information regarding the number of noise channels to create and what time delay should be applied to each of the noise channels - recall that SSN and ISTS are single channel files.|
|createHINTlookup.m|Very basic function to create a lookup table for HINT. This basically uses Wu's originaly HINT lookup table (well, a manually edited version of it anyway ... CWB removed some of the file name information), and appends a suffix to the file names. This allows modcheck_HINT_GUI to successfully lookup sentence information.|
|createMLSTlookup.m| This function creates a suitable lookup table for MLST stimuli. This uses the provided MLST word list (sent to CWB by Wu) to create something closer to the HINT lookup table that is more robust. |
|db2amp.m| Convert decibels to amplitude (magnitude)|
|erplab_linespec.m| Function to kick back default color and line style values similar to ERPLAB. Not tested to see whether or not colors actually match precisely, so take color with a grain of salt. Code cannibalized from ploterps.m (part of ERPLAB).|
|fade.m|Function to fade sounds in/out by applying a window over a specified time range. Uses MATLAB's "window" function to create the fade in/fade out ramps.|
|fftplot.m| Plot amplitude spectrum of time series. |
|fillPlaybackMixer.m| Function to create a mixer of appropriate size for the playback device. This proved useful when using SIN on machines with different devices (e.g., 8-channel playback using the Halo Claro and two-channel sound playback using standard two channel cards).|
|filter_table.m|  This function returns a filtered version of the original table that satisfies all user-specified criteria. The criteria are essentially fields and their corresponding acceptable values. Note: this is a more generalized version of import_HINT.m|
|filterA.m| Not used by SIN. |
|findcell.m| Borrowed from ERPLAB's deprecated functions. Thanks to Javier! |
|getCases.m| Borrowed from MATLAB file exchange.|
|getMatchingStruct.m| Function to find structures that match fieldnames and values provided by the user. This proved useful when trying to identify a specific modifier within a group of modifiers, but can be used to match any field within any set of structures.|
|git_is_current.m| Function determines if a repository is fully up to date with all changes committed or not.|
|git_sha.m|This function returns the SHA key for a GIT repository using the git.exe. Note that git.exe must be in the system path for this to work properly. |
|Hagerman_getsignal.m| Function to extract a signal from a pair of (phase inverted) Hagerman recordings. The non-phase inverted signal is returned along with its samppling rate. Note that the function assumes that the data are already time aligned. If this is not the case, then call align_timeseries.m before calling Hagerman_getsignal.m. If the signals are not temporally aligned, the output will be meaningless. |
|Hagerman_record.m| One of the first files developed for SIN. This was intended to be a standalone script to perform Hagerman-like recordings. CWB later modularized these routines to play nicely with player_main.m This is no longer used. |
|HINT_chooseAlgo.m| Function to select the current algorithm being used for spech in noise testing (e.g., HINT, MLST) on a given trial.|
|HINT_GUI.m| HINT scoring GUI. Recycled for MLST.|
|HINT_score2binary.m| Function to convert scoring arrays to a binary outcome for use with HINT and other similar tests. This is designed to work specifically with the scoring matrix generated by modcheck_HINT_GUI, but should be adaptable to other circumstances without too much trouble.|
|importHINT.m| Function to import HINT information from XLSX file. Can also return information specific satisfying search criteria (under development). If not search criteria are provided, then information for the entire list is returned. Note: CWB recommends using load_lookup_table.m instead.|
|Instructions.m| Code for Instructions GUI. |
|is_reversal.m|  This function takes a time series, data, and determines which points are likely reversals (e.g., a reversal in the direction of change). This was written and intended to be used in combination with tests like the HINT (SNR-80 ...) and other adaptive algorithms that are required to terminate after a specific number of reversals.|
|iseegstruct.m| Borrowed from ERPLAB|
|iserpstruct.m| Borrowed from ERPLAB|
|label_datapoint.m| Adds a text label to a point in a figure. Does some basic checks to make sure the text is generally visible, but uses some plausible hard-coded values to do so. Might need to be more dynamic. |
|lineplot2d.m|  Function to create two-dimensional line plots complete with error bars (if specified). CWB found that he was recycling a lot of code to create similar line plots in various functions for project AA, so decided to centralize the plotting routines. |
|load_lookup_table.m| Load a lookup table and return a table structure. This is how CWB should have written importHINT, but he didn't have the time to do it properly. SO, now he gets to rewrite it and deal. |
|make_stimuli.m| Script to make calibrated stimuli for all (current) SIN Tests. |
|map_channels.m| This function creates a channel mapping matrix used by PsychPortAudio to do appropriate sound mappings. Use iterative calls for playback/recording sound setup since these are currently handled in different mat files. |
|match_spectra.m| This function can be used to match the spectra of two time series. Below is an approximate outline of the procedure implemented here. Please note that there are *many* ways to do spectral matching and this may not be the best solution for your specific circumstance. This function uses a spectral estimator (pwelch) to estimate the PSDs of two time series and then attempts to filter these time series such that the PSDs are a close approximation of each other. Note that SIN_matchspectra provides an alternative method, but tends to be very slow and generally oerfits the data. CWB wrote this as a faster, more streamlined, and more principled alternative. |
|mex_uuid.m| Borrowed from MATLAB file exchange.|
|mixer2pan.m| Function to convert a DxP mixer to a pan string used by the pan parameter in FFmpeg. No longer used. |
|MLST_makemono.m| Function to set one of the audio channels in MLST MP4 files to 0. MP4s associated with MLST are stereo by default. We only want the audio to play speech out of a single speaker. To do this, we'll edit the MP4s  using FFmpeg. No longer used.|
|modcheck_ANLGUI.m| Modcheck function coupled with ANL_GUI. ANL_GUI is a simple "run", "pause", "stop" GUI. This function returns codes compatible with modifier_PlayControl based on toggled buttons|
|modcheck_HINT_GIU.m| Modcheck for HINT.|
|modcheck_wordspan_gui.m| Modcheck for Word Span. |
|modifier_append2playlist.m| %   Appends new playback data to the playback list in player_main. This
%   proved useful when using adaptive algorithms (e.g., 3down1up for
%   SNR-80 estimation) that may require more stimuli than originally
%   specified by the user.
%
%   This essentially just calls SIN_getPlaylist with the user-provided
%   settings as written the SIN options structure. These values are then
%   appended to the 'stim' variable in player_main. 
%
%   Note: This function intentionally ignores values in the "files" field
%   of specific.genPlaylist. The assumption is that we're looking for a
%   *new* playlist to append to the playback list in player_main|
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
|SIN_makeFilter.m| This function is no longer used by anything in SIN. |
|SIN_maskdomain.m| |
|SIN_matchspectra.m| Spectrally match two time-series in the frequency domain. The algorithm is horribly inefficient and prohibitively slow with even modest time series. I recommend using match_spectra.m instead.|
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
