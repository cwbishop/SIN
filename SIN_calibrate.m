function [allresults]=SIN_calibrate(X, varargin)
%% DESCRIPTION:
%
%   This function is designed to calibrate stimuli for various
%   playback/recording loops. There are several steps to this process.
%
%       1. The noise floor is measured. This is done by acquiring a
%       recording with no active playback (zeros in all channels). 
%
%       2. A calibration stimulus is presented from each playback channel
%       in turn and recorded. 
%
%       3. The power spectra between the ideal response (PSD of the output
%       stimulus) and the recorded response are compared. A filter is
%       estimated (see SIN_makeFilter) to correct for the transfer function
%       of the playback/recording loop. The specifics of the filter
%       making process is necessarily user defined (e.g., filter order,
%       what to do with DC component, which frequencies to attempt to
%       correct, etc.). 
%
%           Note: The noise floor may be used to remove noise from the
%           environment or recording loop; the latter is often a problem
%           with probe microphones. (This feature is not well-tested,
%           though, so use with a suitable degree of caution)
%
%       4. 
%
%
%   Note: While the code is written to work with nearly any stimulus, CWB
%   strongly encourages the user to use a sufficiently long broadband
%   stimulus (e.g., 10 s of white noise). Narrow band stimuli can (in
%   theory) be used for calibration purposes, but may lead to inaccuracies.
%   
%
% INPUT:
%
%   X:  file used to calibrate physical device channels (e.g., speakers,
%       earphones, whatever)
%
% Parameters (in 'specific' field):
%
%   'physical_channels':    integer array, physical channels to calibrate
%
%   'data_channels':    integer, which channel of X to use for calibration.
%                       
%   'output_root':  root for calibration output files. These are all
%                   "results" data structures returned from
%                   portaudio_adaptiveplay. The only exception is the
%                   compiled calibration.mat file, which has a smaller,
%                   easier to digest data structure with filters for each
%                   calibrated channel. 
%   
% Analysis flags (in 'specific' field):
%
%   'remove_noise_floor':    bool, partial out contribution of
%                       environmental/recording loop noise during filter
%                       estimation. 
%
%   'validate': bool, filter calibration stimulus and repeat calibration
%               process. If the filter (and corrected range) are
%               appropriate, then this should lead to well-matched spectra
%               between the output stimulus and the recording from each
%               channel. 
%
%                   Note: In many cases, speakers are simply incapable of
%                   producing power in specific frequency ranges (typically
%                   in higher frequency ranges for average speakers used
%                   for human research). If this is the case, the user will
%                   never be able to correct this frequency range fully.
%                   Instead, CWB encourages the user to only attempt to
%                   correct within the experimentally relevant range. 
%
%   'write_files':  bool, XXX maybe a user prompt might be more effective
%                   here? XXX
%
% OUTPUT:
%
%   XXX Lots of information XXX
%
% Development:
%
%   1. Write a procedure to recommend a frequency range to correct. This
%   can probably be done by presenting white noise and then determining
%   the low and high-frequency cutoffs. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:});

% Playback sampling rate
FS=d.player.playback.fs; 

%% CREATE CALIBRATION DIRECTORY
[PATHSTR,NAME,EXT] = fileparts(d.specific.output_root);
mkdir(PATHSTR); 

%% RECORD REFERENCE
%   - For testing purposes, just play a 1 kHz tone from the speakers. 
%   - This will *not* be super accurate, but should at least give us a
%   semi-realistic sense of how the code is (or is not) working

%% LOAD PLAYBACK STIMULUS
%   - Load the playback stimulus that will be used to calibrate the
%   speakers.
t.dtype = 2;    % only accept wav files for now.
[stim, fs]=SIN_loaddata(X, t); 
Xdim=size(stim); 

% Resample stimulus
%   Should really wrap this into SIN_loaddata so I know I'm getting the
%   same data across functions. 
stim=resample(stim, d.player.playback.fs, fs); 

% Get figure title from options structure
figtitle = d.player.modcheck.title; 

%% RECORD NOISE FLOOR
%
%   This section is used to estimate the noise levels of the recording
%   loop/environment. It will (eventually) be used below to estimate SNR of
%   the calibration and playback stimulus. If the SNR is too low, we'll
%   throw a warning and make the user redo the test. What "too low" is will
%   be open to debate. 
%
%   The noise floor can also be used to estimate (and correct for) the
%   power spectrum of the recording loop. 

% call calibrate_runTest
[~, noise_floor]=calibrate_runTest(X, d, zeros(Xdim(2), d.player.playback.device.NrOutputChannels), ...
    d.specific.instructions.noise_estimation, ...
    [figtitle 'Noise Estimation'], ...
    fullfile(PATHSTR, [NAME '-Noise_Estimation'])); 

%% RECORD RESPONSE FROM EACH OUTPUT CHANNEL
%   The output is recorded and later used to estimate a corrective filter
%   for each channel. SIN_makeFilter is used to generate these filters. 

% Loop through each physical channel in turn
for p=1:length(d.specific.physical_channels)
    
    % Reset mixer
    mod_mixer=zeros(Xdim(2), d.player.playback.device.NrOutputChannels);
    
    % Present specified data channel to physical device
    mod_mixer(d.specific.data_channels, d.specific.physical_channels(p))=1; 
    
    % call calibrate_runTest
    results = calibrate_runTest(X, d, mod_mixer, ...
    d.specific.instructions.playback, ...
    [figtitle 'Channel ' num2str(d.specific.physical_channels(p))], ...
    fullfile(PATHSTR, [NAME '-Channel_' num2str(d.specific.physical_channels(p))])); 

    % Copy recorded information to a cell array
    %   Easier to do spectrum matching below.
    rec{p} = results.RunTime.sandbox.mic_recording{1}(:, d.specific.record_channels); 
    
    % Compute corrective filter
    %   Call to non-existent SIN_makeFilter here.
    %
    %   Note: CWB is trying to create a zero-phase filter; that is, one
    %   that can be used with filtfilt. So the math is divided by 2 to
    %   account for the double filtering.         
    if d.specific.remove_noise_floor
        domath = '( (X1 - X2 - X3) - mean((X1 - X2 - X3)) )./2';    % Removes noise power from filter estimate.
                                                                    % Also mean center to maintain original RMS value. I think ...                                                                 
    else
        domath = '( (X1 - X2) - mean(X1-X2) )./2';  % Do not remove noise floor, but remove mean to preserve RMS value. 
    end % if d.specific
    
    % Get a filter appropriate for use with filtfilt
    filt(:, p)=SIN_makeFilter(stim, rec{p}, noise_floor, d.specific.makeFilter, 'domath', domath, 'datatype', 'tsdata'); 
    
    % Clear out dangerous variables
    %   We don't want to screw up everything by letting this variable
    %   linger.
    clear results mod_mixer
    
end % for p=1: ...
    
%% SAVE INFORMATION IN CALIBRATION FILE
%   Save the relevant information in a calibration file
calibration=struct(...    
    'reference',    struct(), ...   % will need recording or at least RMS value of recording. 
    'filter',   struct(...
        'FS',   FS, ... % sampling rate of filter. This might not always equal the playback rate, so we need to have a way to deal with this.
        'F',    F,  ... % frequencies corresponding to each bin of freq_filter
        'physical_channels',    [d.specific.physical_channels], ...
        'freq_filter',   dPyy));    % filter (in dB)

% Save to file
save(fullfile(PATHSTR, [NAME '-Calibration']), 'calibration'); 

function [results, rec]=calibrate_runTest(X, d, mod_mixer, instructions, figtitle, fname)
%% DESCRIPTION:
%
%   Function to populate the necessary fields during calibration, run the
%   calibration test, write data to file.
%
% INPUT:
%
%   X:  single element cell array, path to calibration wav file. 
%
%   mod_mixer:  data_channels x physical_channels mixer. 
%
%   instructions:   string, instructions to present to user during this
%                   particular stage of testing.
%
%   figtitle:   string, figure title
%
%   fname:  string, path to where the results structure should be saved.
%
% OUTPUT:
%
%   results:    results structure from portaudio_adaptiveplay
%
% Development:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   6/14

% Create mod_mixer for portaudio_adaptiveplay
%   Assume we aren't putting any data into any output channels
d.player.mod_mixer=mod_mixer; 

% Set instructions in ANL_modcheck_keypress
d.player.modcheck.instructions=instructions; 

% Set title
d.player.modcheck.title = figtitle; 

% Run portaudio_adaptiveplay
results = portaudio_adaptiveplay(X, d); 

% Get recorded response from larger results structure 
rec=results.RunTime.sandbox.mic_recording{1}(:, d.specific.record_channels); 

% Save results to file
save(fname, 'results'); 