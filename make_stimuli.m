%% DESCRIPTION:
%
%   This is the master M-File used to create/calibrate all stimuli used
%   in stim from the base HINT/MLST/ANL stimuli provided with these tests.
%

% Clear the stack
% clear all;

%% VARIABLES THAT APPLY ACROSS MORE THAN ONE STIMULUS SET
% Frequency range for IIR filtering below. This frequency range should be
% used in all subsequent stimulus sets as well. 
filter_frequency_range = [125 10000];

% We want a 4th order bandpass filter (really 8th order since we're using
% filtfilt).
filter_type = 'bandpass';
bandpass_filter_order = 4; 

% Spectral matching filter information
spectral_match_filter_order = 400; 

% Bitdepth for audio files. This should be used in all subsequent write
% calls as well. 
audio_bit_depth = 24; 
FS = 44100; % sampling rate of all audio files

% Periodogram parameters
pwelch_window = FS; % pwelch_window in seconds
pwelch_noverlap = [];
pwelch_nfft = FS;

%% CREATE HINT + SPEECH SHAPED NOISE (SPSHN) STIMULI
% ===================================
% Create a calibrated HINT SPSHN file, then use this to calibrate the
% concatenated HINT corpus. 
% ===================================

% Amplitude used for silence detection
hint_ampthresh = 0.0001;

scale = SIN_CalAudio(fullfile('playback', 'Noise', 'HINT-Noise.wav'), ...
    'testID', 'HINT (SNR-50, keywords, 1up1down)', ...
    'nmixer', [db2amp(-21); 0], ...
    'targetdB', 0, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh, ...
    'bitdepth', audio_bit_depth, ...
    'suffix', ';0dB', ...
    'tmixer', [0;1], ...
    'omixer', 1, ...
    'writeref', true, ...
    'wav_regexp', '[0-9]{2}.wav', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order);

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

% Concatenate the files 
[hint_time_series, fs] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh); 

% ===================================
% Add noise to newly created HINT stimuli
%   This section of code adds silent periods to the beginning and end of
%   sentences and adds in a noise track (channel 2) that can later be
%   mixed.
% ===================================
addnoise2HINT(fullfile('playback', 'Noise', 'HINT-Noise;0dB.wav'), ...
    'testID', 'HINT (SNR-50, keywords, 1up1down)', ...
    'wav_regexp', '[0-9]{2};0dB.wav$', ...
    'tmixer', [1 0], ...
    'nmixer', [0 1], ...
    'leadlag', [1 1], ...
    'suffix', '+spshn', ...
    'noiserange', [0.5 5.5], ...
    'bitdepth', audio_bit_depth, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh*scale, ...
    'chan4silence', 1);

%% CREATE HINT + MULTI-TALKER BABBLE (ISTS) STIMULI
% ===================================
% Create a calibrated, spectrally matched ISTS stimulus for HINT
%
%   The ISTS should be calibrated and spectrally matched to the HINT SPSHN
%   sample described above. This will (effectively) bandpass filter the 
%   ISTS as well, since the SPSHN is already bandpass filtered. 
%
%   This will need to be saved as a separate file because its spectrum may
%   not be appropriate for other tests (likely). 
% ===================================

% Load original ISTS
[ists, ists_fs] = SIN_loaddata((fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS-V1.0_60s_24bit.wav'))); 
[hint_spshn, hint_fs] = SIN_loaddata((fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise;0dB.wav'))); 
if ists_fs ~= hint_fs, error('sampling rates differ'); end

% Band pass filter ISTS 
[b, a] = butter(bandpass_filter_order, filter_frequency_range./(ists_fs/2), filter_type);
ists_filt = filtfilt(b, a, ists);

% Match ISTS to HINT SPSHN
[ists_filt] = match_spectra(hint_spshn, ists_filt, ...
        'fsx', hint_fs, ...
        'fsy', ists_fs, ...
        'plot', true, ...
        'frequency_range', [eps inf], ... % excludes DC component
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Get pwelch for concatenated hint sentences
[Pxx, pwelch_freqs] = pwelch(hint_time_series, pwelch_window, pwelch_noverlap, pwelch_nfft, fs); 

% Get pwelch for speech shaped noise sample
hint_spshn = SIN_loaddata(fullfile('playback', 'Noise', 'HINT-Noise;0dB.wav'));
P_spshn = pwelch(hint_spshn, pwelch_window, pwelch_noverlap, pwelch_nfft, fs); 

% Get pwelch for ISTS
P_ists = pwelch(ists_filt, pwelch_window, pwelch_noverlap, pwelch_nfft, fs); 

% Plot results
figure, hold on
plot(pwelch_freqs, db([Pxx P_spshn P_ists], 'power'))
legend('Concatenated Sentences', 'Sphn', 'ISTS')
title('HINT PSDs')
ylabel('PSD (dB/Hz)');
xlabel('Frequency (Hz)');
% Bandpass filter the ISTS stimulus
% [b, a] = butter(bandpass_filter_order, filter_frequency_range./(ists_fs/2), filter_type);
% ists_filt = filtfilt(b,a,ists); 


% Scale spectrally matched ISTS to match rms levels to HINT spshn

% Write spectrally matched/calibrated ISTS for HINT