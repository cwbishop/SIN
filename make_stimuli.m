%% DESCRIPTION:
%
%   This is the master M-File used to create/calibrate all stimuli used
%   in stim from the base HINT/MLST/ANL stimuli provided with these tests.
%

% Clear the stack
clear all;

%% CREATE HINT + SPEECH SHAPED NOISE (SPSHN) STIMULI
% ===================================
% Create a calibrated HINT SPSHN file, then use this to calibrate the
% concatenated HINT corpus. 
% ===================================

% Amplitude used for silence detection
hint_ampthresh = 0.0001;

% Frequency range for IIR filtering below. This frequency range should be
% used in all subsequent stimulus sets as well. 
filter_frequency_range = [125 10000];

% We want a 4th order bandpass filter (really 8th order since we're using
% filtfilt).
filter_type = 'bandpass';
filter_order = 4; 

% Bitdepth for audio files. This should be used in all subsequent write
% calls as well. 
audio_bit_depth = 24; 

scale = SIN_CalAudio(fullfile('playback', 'Noise', 'HINT-Noise.wav'), ...
    'testID', 'HINT (SNR-50, keywords, 1up1down)', ...
    'nmixer', [db2amp(-21); 0], ...
    'targetdB', 0, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh, ...
    'bitdepth', audio_bit_depth, ...
    'suffix', ';0dB', ...
    'tmixer', [0;1], ...
    'omixer', [1 0], ...
    'writeref', true, ...
    'wav_regexp', '[0-9]{2}.wav', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', filter_order);

% ===================================
% Confirm that the SPSHN sample is spectrally matched to the HINT corpus
%   This section of code will concatenate all HINT sentences (before
%   we add noise as a second track) and compare the long-term spectrum to
%   the long-term spectrum of the SPSHN stimulus. 
%
%   This will (hopefully) confirm that the two are well-matched and we
%   won't have to do anything. Otherwise, we'll have to apply our spectral
%   matching procedure here as well. 
% ===================================

% Get a list of HINT sentences using SIN functions
opts = SIN_TestSetup('HINT (SNR-50, keywords, 1up1down)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2};0dB.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 



% ===================================
% Add noise to newly created HINT stimuli
%   This section of code adds silent periods to the beginning and end of
%   sentences and adds in a noise track (channel 2) that can later be
%   mixed.
% ===================================

%% CREATE HINT + MULTI-TALKER BABBLE (ISTS) STIMULI
% ===================================
% Create a calibrated, spectrally matched 
% ===================================

