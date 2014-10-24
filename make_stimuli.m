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
spectral_match_filter_order = 800; 

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

% Random noise seed for noise sample selection
hint_random_noise_seed = '1000';

% MLST threshold 
mlst_ampthresh = 0.01; 

% Hagerman settings
%   hagerman_snrs: the SNRs to test
%   hagerman_sentence_number:   number of sentences to use in hagerman
%   recordings
hagerman_snrs = [-15:5:15];
hagerman_sentence_number = 5; % use 5 for testing purposes, will need to change to 50 for the experiment proper. 

% ===================================
% Match the long-term spectrum of the spshn spectrum to the long-term
% spectrum of the concatenated HINT corpus
% ===================================

% Get a list of HINT sentences using SIN functions
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2}.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Load the speech shaped noise file
[hint_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Just use channel 1 of hint_spshn
hint_spshn = hint_spshn(:,1); 

% Concatenate the HINT Corpus
[hint_time_series, hint_fs] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh, ...
    'mixer', [0;1]); 

% sample rate check
if spshn_fs ~= hint_fs, error('Mismatched sample rates'); end 

% We need to create a SPSHN stimulus that is spectrally-matched to the HINT
% speech corpus (concatenated sentences). We just need to spectrally match
% in a high-pass sense. We don't bandpass filter here because bandpass
% filtering is implicitly done in the call to SIN_CalAudio below. 
[hint_spshn] = match_spectra(hint_time_series, hint_spshn, ...
        'fsx', hint_fs, ...
        'fsy', hint_fs, ...
        'plot', true, ...
        'frequency_range', [filter_frequency_range(1) inf], ... % only work on the higher frequencies.
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Write spectrally matched SPSHN file
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-SPSHN.wav'), hint_spshn, hint_fs, 'BitsperSample', audio_bit_depth);

% Using the spectrally matched SPSHN sample above, calibrate the whole
% corpus. 
hint_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-SPSHN.wav'), ...
    'testID', 'HINT (SNR-50, SPSHN)', ...
    'nmixer', db2amp(-22), ...
    'targetdB', 0, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh, ...
    'bitdepth', audio_bit_depth, ...
    'suffix', ';bandpass;0dB', ...
    'tmixer', [0;1], ...
    'omixer', 1, ...
    'writeref', true, ...
    'wav_regexp', '[0-9]{2}.wav', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order);

% The output SPSHN (HINT-SPSHN;bandpass;0dB.wav) is our calibration
% stimulus moving forward. That is, all other calibration procedures should
% use THIS file, not HINT-SPSHN. Recall that HINT-SPHN is not bandpass
% filtered. 
calibration_file = fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-SPSHN;bandpass;0dB.wav');

% Confirm that spectral matching procedure led to good results. 

% Need to get the new 0dB hint_time_series
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Concatenate the HINT Corpus
[hint_time_series, hint_fs] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', 1);

% Load the speech shaped noise file
hint_spshn = SIN_loaddata(calibration_file); 

% Replace this call with plot_psd
plot_psd({ hint_time_series hint_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 
    
% ===================================
% Add speech-shaped noise to newly created HINT stimuli
%   This section of code adds silent periods to the beginning and end of
%   sentences and adds in a noise track (channel 2) that can later be
%   mixed.
% ===================================
addnoise2HINT(calibration_file, ...
    'testID', 'HINT (SNR-50, SPSHN)', ...
    'wav_regexp', '[0-9]{2};bandpass;0dB.wav$', ...
    'tmixer', [1 0], ...
    'nmixer', [0 1], ...
    'leadlag', [1 1], ...
    'suffix', '+spshn', ...
    'noiserange', [0.5 50], ... % use a 50 second noise sample
    'bitdepth', audio_bit_depth, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh*hint_scale, ...
    'random_noise_seed', str2double(hint_random_noise_seed));     

% Create HINT Lookup table
createHINTlookup(';bandpass;0dB+spshn');

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
%
%   Note: We need to create a 3-talker ISTS by temporally shifting and
%   adding the single-talker ISTS.
% ===================================

% Load original ISTS
[ists, ists_fs] = SIN_loaddata((fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS-V1.0_60s_24bit.wav'))); 
if ists_fs ~= hint_fs, error('sampling rates differ'); end
if spshn_fs ~= hint_fs, error('Sampling rates differ'); end

% Band pass filter ISTS 
[b, a] = butter(bandpass_filter_order, filter_frequency_range./(hint_fs/2), filter_type);
ists_filt = filtfilt(b, a, ists);

% Match ISTS to concatenated HINT corpus. 
[ists_filt] = match_spectra(hint_time_series, ists_filt, ...
        'fsx', hint_fs, ...
        'fsy', hint_fs, ...
        'plot', true, ...
        'frequency_range', [eps inf], ... % excludes DC component
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Need to RMS scale the filtered ISTS to match our calibration stimulus.
% This will produce a single-channel, 1-talker ISTS stimulus that is
% calibrated to ~0 dB relative to the calibration stimulus. 
ists_scale = rms(hint_spshn) ./ rms(ists_filt);
ists_filt = ists_filt .* ists_scale;

% Write spectrally matched/calibrated ISTS for HINT
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS_1_talker;bandpass;0dB.wav'), ists_filt, hint_fs, 'BitsperSample', audio_bit_depth);

% Make 3-talker ISTS
%   Note that the timing offsets were selected through some trial and error
%   by CWB. His goal was to minimize temporal gaps (that is, periods of
%   relative silence) when summing the signal over channels.
ists_3talker = remixaudio(ists_filt, ...
    'fsx',    hint_fs, ...
    'mixer',    [1 1 1], ...
    'toffset',  [0 11.234 28.1987], ...
    'writetofile',  false); 

% Confirm that RMS is the same for all channels
db(rms(ists_3talker)) - db(rms(ists_filt)) 

% Write the 3-talker version
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS_3_talker;bandpass;0dB.wav'), ists_3talker, hint_fs, 'BitsperSample', audio_bit_depth);

% Need to calculate the scaling factor that needs to be applied to each
% of the ISTS channels (talkers) to collapse them into a single channel. 
ists_scale4hint = rms(hint_spshn)./rms(sum(ists_3talker,2));

% Add ISTS noise to HINT stimuli
%   nmixer is DxP, where D is the number of channels in the wav file and P
%   is the number of output channels 
addnoise2HINT(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS_3_talker;bandpass;0dB.wav'), ...
    'testID', 'HINT (SNR-50, SPSHN)', ...
    'wav_regexp', '[0-9]{2};bandpass;0dB.wav$', ...
    'tmixer', [1 0], ...
    'nmixer', [ [zeros(size(ists_3talker,2),1)] [ists_scale4hint; ists_scale4hint; ists_scale4hint] ], ...
    'leadlag', [1 1], ...
    'suffix', '+3talker_ists', ...
    'noiserange', [0 60], ...
    'bitdepth', audio_bit_depth, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh*hint_scale, ...
    'random_noise_seed', str2double(hint_random_noise_seed)); % seed with subject identifier. hard-coded here, but will wrap this into a function later.

% Clear SPSHN and ISTS variables and read them in fresh from file to make
% sure we have calibrated these correctly and nothing is botched when
% writing to file.
clear ists_filt ists
[ists, ists_fs] = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS_1_talker;bandpass;0dB.wav'));

% Get pwelch for concatenated hint sentences
[Pxx, pwelch_freqs] = pwelch(hint_time_series, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for speech shaped noise sample
P_spshn = pwelch(hint_spshn, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for ISTS
P_ists = pwelch(ists, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Plot results
figure, hold on
plot(pwelch_freqs, db([Pxx P_spshn P_ists], 'power'), 'linewidth', 1.5)
legend('Concatenated Sentences', 'SPSHN', 'ISTS', 'location', 'NorthOutside')
title('HINT PSDs')
set(gca, 'XScale', 'log')
ylabel('PSD (dB/Hz)');
xlabel('Frequency (Hz)');
grid on

% Compute decibel differences between the concatenated HINT corpus, SPSHN,
% and ISTS
figure
plot(1, [db(rms(hint_time_series)) db(rms(hint_spshn)) db(rms(ists))], 's')
legend('Concatenated HINT Corpus', 'SPSHN', 'ISTS', 'location', 'NorthOutside');
ylabel('dB')
title('Relative HINT Stimulus Levels'); 

%% ACCEPTABLE NOISE LEVEL (ANL) CALIBRATION
% ===================================
%   This segment of code writes a bandpass and RMS normalized version of
%   the ANL. 
%
%   Note: we do NOT want to do any spectral matching here.
% ===================================

% Load ANL
[anl, anl_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'ANL', 'ANL.wav'));
if anl_fs ~= hint_fs, error('Sampling rates do not match'); end 

% Bandpass filter ANL
anl_filt = filtfilt(b, a, anl); 

% The RMS estimates from the two ANL channels *differ*. CWB decided to
% match them more closely than their creators. 
anl_filt(:,2) = anl_filt(:,2).*(db2amp(db(rms(anl_filt(:,1))) - db(rms(anl_filt(:,2)))));
db(rms(anl_filt)) % verify that the levels are now matched. Both should evaluate to -17.4319

% Calculate scaling factor
anl_scale = rms(hint_spshn)./rms(anl_filt(:,1)); 

% RMS normalize ANL
anl_filt = anl_filt.*anl_scale; 

% Write ANL
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'ANL', 'ANL;bandpass;0dB.wav'), anl_filt, anl_fs, 'BitsperSample', audio_bit_depth);

% Visualization
figure, hold on
plot(1, [db(rms(hint_spshn)) db(rms(anl_filt))], 's', 'linewidth', 1.5); 
title('ANL RMS Normalization');
ylabel('dB');
legend('HINT SPSHN', 'ANL (Channel 1)', 'ANL (Channel 2)', 'location', 'NorthOutside'); 

%% Hagerman
% ===================================
%   Create stimuli used in Hagerman style recordings. This will loosely
%   involve the following steps.
%
%       - Selecting a subset of calibrated stimuli from the HINT
%
%       - Creating a custom, spectrally matched speech-shaped noise (SPSHN)
%       and ISTS. The spectra of these maskers will be matched to the
%       long-term spectra of the subset of HINT stimuli
%
%       - RMS normalizing these maskers (again) to make sure we have not
%       changed their RMS values. These must be normalized to the 
%       calibrated SPSHN stimulus used to create the HINT stimui 
%           fullfile('playback', 'Noise', 'HINT-SPSHN;bandpass;0dB.wav'))
%
%       - Call "createHagerman" with the desired SNR values and stimuli.
%
% Note: Should we be doing the spectral matching with the replicated noise
% samples? That is, we might need to repeat the first section of the noise
% to create a noise sample that is long enough for 40 sentences ... if
% that's the case, we should probably be spectrally matching based on the
% noise sample we'll be using - repeats included ...
%
% CWB unsure about this still ...
% ===================================

% Select a subset of HINT sentences
%   Use the first 40 sentences in the corpus.
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB.wav$';

% Get the file names and massage them into a useful format.
[~, hagerman_audio_files] = SIN_stiminfo(opts); 
hagerman_audio_files = concatenate_lists(hagerman_audio_files); 
hagerman_audio_files = {hagerman_audio_files{1:hagerman_sentence_number}}';
hagerman_time_series = concat_audio_files(hagerman_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', 1); 

% RMS normalize the concatenated sentences to calibration stimulus
hint_spshn = SIN_loaddata(calibration_file);
hagerman_time_series = hagerman_time_series .* (rms(hint_spshn)./rms(hagerman_time_series));

% Load ORIGINAL the speech shaped noise file
%   We want to basically start over so we aren't filting this noise file
%   more than the one used for HINT. If we started with the completed
%   version of HINT-SPSHN and filtered that, then our filter order would be
%   twice what we expect it to be here. So some recreating the wheel is
%   necessary. 
[hagerman_spshn, hagerman_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Just use channel 1 of hint_spshn
hagerman_spshn = hagerman_spshn(:,1); 

% Bandpass filter 
hagerman_spshn_filt = filtfilt(b, a, hagerman_spshn); 

% Create speech shaped noise sample
[hagerman_spshn_filt] = match_spectra(hagerman_time_series, hagerman_spshn_filt, ...
        'fsx', hint_fs, ...
        'fsy', hint_fs, ...
        'plot', true, ...
        'frequency_range', [eps inf], ... % exclude DC component
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);
    
% RMS normalize to calibration stimulus
hagerman_scale = rms(hint_spshn)./rms(hagerman_spshn_filt); 
hagerman_spshn_filt = hagerman_spshn_filt .* hagerman_scale; 

% Check dB values
db(rms(hint_spshn)) - db(rms(hagerman_spshn_filt)) 

% Write to file
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'Hagerman-SPSHN;bandpass;0dB.wav'), hagerman_spshn_filt, hagerman_fs, 'BitsperSample', audio_bit_depth);

% ===================================
% Create the ISTS (spectrally matched) ISTS stimulus for Hagerman
% recordings. 
%
%   Again, we want to start from scratch here (that is, load the original
%   file) so we don't double our filter order. See discussion above for
%   more details. 
% ===================================
[hagerman_ists, ists_fs] = SIN_loaddata((fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS-V1.0_60s_24bit.wav'))); 
if ists_fs ~= hint_fs, error('sampling rates differ'); end

% Band pass filter ISTS 
[b, a] = butter(bandpass_filter_order, filter_frequency_range./(hint_fs/2), filter_type);
hagerman_ists_filt = filtfilt(b, a, hagerman_ists);

% Match ISTS to concatenated HINT corpus. 
[hagerman_ists_filt] = match_spectra(hagerman_time_series, hagerman_ists_filt, ...
        'fsx', hint_fs, ...
        'fsy', hint_fs, ...
        'plot', true, ...
        'frequency_range', [eps inf], ... % excludes DC component
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Need to RMS scale the filtered ISTS to match our calibration stimulus
hagerman_ists_scale = rms(hint_spshn) ./ rms(hagerman_ists_filt);
hagerman_ists_filt = hagerman_ists_filt .* hagerman_ists_scale;

% Check RMS levels
db(rms(hint_spshn)) - db(rms(hagerman_ists_filt))

% Write spectrally matched/calibrated ISTS for HINT
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'Hagerman-ISTS;bandpass;0dB.wav'), hagerman_ists_filt, hint_fs, 'BitsperSample', audio_bit_depth);

% ===================================
% Confirm that hagerman_time_series (concatenated HINT sentences), Hagerman
% Speech Shaped Noise, and the Hagerman ISTS are well-matched spectrally
% and in terms of sound pressure level (SPL). 
% ===================================

% Get pwelch for concatenated hint sentences
[Pxx, pwelch_freqs] = pwelch(hagerman_time_series, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for speech shaped noise sample
P_spshn = pwelch(hagerman_spshn_filt, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for ISTS
P_ists = pwelch(hagerman_ists_filt, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

figure, hold on
plot(pwelch_freqs, db([Pxx P_spshn P_ists], 'power'), 'linewidth', 1.5)
legend('Concatenated Sentences', 'SPSHN', 'ISTS', 'location', 'NorthOutside')
title('Hagerman PSDs')
set(gca, 'XScale', 'log')
ylabel('PSD (dB/Hz)');
xlabel('Frequency (Hz)');
grid on

% RMS levels for Hagerman stimuli
figure
plot(1, [db(rms(hagerman_time_series)) db(rms(hagerman_spshn_filt)) db(rms(hagerman_ists_filt))], 's')
legend('Hagerman (40 HINT Sentences)', 'Hagerman SPSHN', 'Hagerman ISTS', 'location', 'EastOutside');
ylabel('dB')
title('Relative Hagerman Stimulus Levels'); 

% ===================================
% Create Hagerman Stimuli with SPSHN
%   The code below will create the actual Hagerman-Style stimuli. 
% ===================================
createHagerman('target_tracks', {hagerman_audio_files}, ...
    'noise_track', {{fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'Hagerman-SPSHN;bandpass;0dB.wav')}}, ...
    'target_input_mixer',   1, ...
    'noise_input_mixer',    1, ...
    'reference_track', calibration_file, ...
    'reference_input_mixer', 1, ...
    'remove_silence',   true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'snrs',     hagerman_snrs, ...
    'noise_window_sec', 0.02, ...
    'output_base_name', fullfile(fileparts(which('runSIN')), 'playback', 'Hagerman', 'spshn;bandpass;0dB.wav'), ...
    'bit_depth',    audio_bit_depth, ...
    'gap_range',    [0.1 0.3], ...
    'target_output_mixer',  [1 0 0 0 0], ...
    'noise_output_mixer',   [0 1 1 1 1], ...
    'noise_time_shift', [0:10:40], ...
    'write_signal_mask',    true, ...
    'estimate_noise_floor', true, ...    
    'noise_floor_sec',  10); 

% ===================================
% Create Hagerman Stimuli with ISTS
%   The code below will create the actual Hagerman-Style stimuli. 
% ===================================
createHagerman('target_tracks', {hagerman_audio_files}, ...
    'noise_track', {{fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'Hagerman-ISTS;bandpass;0dB.wav')}}, ...
    'target_input_mixer',   1, ...
    'noise_input_mixer',    1, ...
    'reference_track', calibration_file, ...
    'reference_input_mixer', 1, ...
    'remove_silence',   true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'snrs',     hagerman_snrs, ...
    'noise_window_sec', 0.02, ...
    'output_base_name', fullfile(fileparts(which('runSIN')), 'playback', 'Hagerman', 'ists;bandpass;0dB.wav'), ...
    'bit_depth',    audio_bit_depth, ...
    'gap_range',    [0.1 0.3], ...
    'target_output_mixer',  [1 0 0 0 0], ...
    'noise_output_mixer',   [0 1 1 1 1], ...
    'noise_time_shift', [0:10:40], ...
    'write_signal_mask',    true, ...
    'estimate_noise_floor', true, ...    
    'noise_floor_sec',  10);

%% MLST + SPSHN
% ===================================
% Create SPSHN sample for MLST
%  
% ===================================
% Get a list of MLST MP4 files sentences using SIN functions
opts = SIN_TestSetup('MLST (AV, Aided, SSN, 65 dB SPL, +8 dB SNR)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$';

% Get the file names and massage them into a useful format.
[~, mlst_audio_files] = SIN_stiminfo(opts); 
mlst_audio_files = concatenate_lists(mlst_audio_files); 

% Load the speech shaped noise file
[mlst_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Just use channel 1 of hint_spshn
mlst_spshn = mlst_spshn(:,1); 

% Concatenate the mlst Corpus
[mlst_time_series, mlst_fs] = concat_audio_files(mlst_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh, ...
    'mixer', [0;1]); 

% Resample the MLST time series to match everything else (44.1 kHz)
mlst_time_series = resample(mlst_time_series, FS, mlst_fs); 

% sample rate check
%   Omitted because we know it's not going to match, but we resampled
%   above. 
% if mlst_fs ~= FS, error('Mismatched sample rates'); end 

% We need to create a SPSHN stimulus that is spectrally-matched to the MLST
% speech corpus (concatenated sentences). We just need to spectrally match
% in a high-pass sense. We don't bandpass filter here because bandpass
% filtering is implicitly done in the call to SIN_CalAudio below. 
[mlst_spshn] = match_spectra(mlst_time_series, mlst_spshn, ...
        'fsx', hint_fs, ...
        'fsy', hint_fs, ...
        'plot', true, ...
        'frequency_range', [filter_frequency_range(1) inf], ... % only work on the higher frequencies.
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Write spectrally matched SPSHN file
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), mlst_spshn, hint_fs, 'BitsperSample', audio_bit_depth);

% Using the spectrally matched SPSHN sample above, calibrate the whole
% corpus. 
mlst_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), ...
    'testID', 'MLST (AV, Aided, SSN, 65 dB SPL, +8 dB SNR)', ...
    'nmixer', db2amp(0), ... % The scaling applied here will be arbitrary, since we'll need to reload and scale this below anyway.
    'targetdB', 0, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh, ...
    'bitdepth', audio_bit_depth, ...
    'suffix', ';bandpass', ...
    'tmixer', [0;1], ...
    'omixer', 1, ...
    'overwritemp4', true, ...
    'writeref', true, ...
    'wav_regexp', '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order);

% The output SPSHN (HINT-SPSHN;bandpass;0dB.wav) is our calibration
% stimulus moving forward. That is, all other calibration procedures should
% use THIS file, not HINT-SPSHN. Recall that HINT-SPHN is not bandpass
% filtered. 
calibration_file = fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-SPSHN;bandpass;0dB.wav');

% Confirm that spectral matching procedure led to good results. 

% Need to get the new 0dB hint_time_series
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '1001');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Concatenate the HINT Corpus
[hint_time_series, hint_fs] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', 1);

% Load the speech shaped noise file
hint_spshn = SIN_loaddata(calibration_file); 

% Replace this call with plot_psd
plot_psd({ hint_time_series hint_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 