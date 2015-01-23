%% DESCRIPTION:
%
%   This is the master M-File used to create/calibrate all stimuli used
%   in stim from the base HINT/MLST/ANL stimuli provided with these tests.
%

% Clear the stack
% clear all;

%% VARIABLES THAT APPLY ACROSS MORE THAN ONE STIMULUS SET

%% Band pass filter settings
%   Wu, Christi, and Bishop decided it would be a good idea to band pass
%   filter all of our sounds between 125 and 10 kHz. This will preserve
%   much of the information important to speech. Also, we cannot
%   practically match the spectra below ~100 Hz using our systems; the
%   playback/recording loop has substantial noise in this frequency range
%   and the speakers are generally unable to produce sound in this
%   low-frequency range.
%
%   The 10-kHz low-pass cutoff was selected based on what we think
%   listener's hearing aids are doing. Miller and Wu mention that few (if
%   any) hearing aids represent sounds above 8 kHz. So low-pass filter at
%   10 kHz to remove much of the (typically unused) higher frequency
%   information.
filter_frequency_range = [125 10000];

% We want a 4th order bandpass filter (really 8th order since we're using
% filtfilt).
filter_type = 'bandpass';
bandpass_filter_order = 4; 

%% Spectral matching filter information
%   Spectral matching is done using SIN's match_spectra function. This
%   function uses fir2 to estimate the ideal frequency response. The filter
%   order of 3000 was selected to ensure that we had sufficient potential
%   in our filter to reshape frequencies down to <125 kHz (our high pass
%   cutoff). 
spectral_match_filter_order = 3000; 

% Bitdepth for audio files. This should be used in all subsequent write
% calls as well. 
%
% Bit depth of 24 used because we are running 24-bit sound cards with ASIO
% drivers. Which means we can't achieve better than 24-bit precision. 
%
% Both sound cards are set to use a playback rate of 44.1 kHz, so all files
% will be written at 44.1 kHz. 
audio_bit_depth = 24; % used when writing WAV files
audio_bit_rate = 192; % Note that 192 is the highest bitrate available on Windows 7. 
FS = 44100; % sampling rate of all audio files

% Spectral estimation paramters
%   Spectral estimation is used in many instances below to estimate the
%   long-term spectra of sounds or speech corpuses (e.g., HINT). MATLAB's
%   pwelch function is the primary work horse here. The parameters below
%   define the required arguments for the spectral estimation process.
pwelch_window = FS; % number of samples to include in each pwelch window
pwelch_noverlap = []; % Use default section overlap (50% according to matlab 2013b)
pwelch_nfft = FS; % Number of FFT points to use in each section. 

% Amplitude used for HINT signal detection
%   CWB empirically determined that the original HINT stimuli provided by
%   Wu have a relatively low noise floor. Thus, samples that exceed 0.0001
%   are considered the first and last point in the signal. See 
%   threshclipaudio for more details
hint_ampthresh = 0.0001;

% We want to hard code the random noise seed for HINT randomization for
% reproducibility reasons. Here, we use '1000'. 
hint_random_noise_seed = '1000';

% Amplitude used for MLST signal detection.
%   The noise floor is considerably higher for the MLST (looks like the
%   beginning and ends of the signal were not zero padded as with the
%   HINT), so we have to use a more liberal threshold to reliably detect
%   signal from the noise floor. 
mlst_ampthresh = 0.01; 

% Hagerman settings
%   hagerman_snrs: the SNRs to test. Currently, we test from -10:5:15 dB
%   SNRs
%   hagerman_sentence_number:   number of sentences to use in hagerman
%   recordings. 
hagerman_snrs = [-10:5:15];
hagerman_sentence_number = 40; % use 5 for testing purposes, will need to change to 40 for the experiment proper.

%% SOUND CARD CHECK STIMULI
%   These stimuli are used to run a basic soundcard check. The test itself
%   is meant to be run in conjunction with some additional hardware,
%   including an oscilloscope and/or frequency analyzer. 
tone = sin_gen(1000, 60, FS);

% Write to file
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'calibration', '1kHz_tone.wav'), tone, FS, 'BitsperSample', audio_bit_depth);

% Clear sin wave
clear tone

%% MAKE A WHITE NOISE SAMPLE
% ===================================
% CWB originally tried to reshape the original HINT speech shaped noise
% sample to match the spectra for other corpuses/conditions. However, there
% are some peculiarities in this noise sample that may not be addressed by
% match_spectra. Specifically, CWB worried about his ability to reshape
% some of the high-frequency information. This is vague, I know, but
% ultimately moot.
%
% Consequently, CWB decided to create a novel white noise stimulus to use
% for spectral reshaping. The procedure goes approximately as follows.
%
%   1. Load the original HINT speech shaped noise stimulus
%   2. Create a white noise sample of the same length as (1)
%   3. RMS scale the white nose sample to match the RMS of (1)
%   4. Write the RMS-scaled white noise sample.
% ===================================

% go ahead and load the HINT file so we can RMS match to this. 
[hint_spshn, hint_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Create white noise sample of the same duration
white_noise = detrend(rand(size(hint_spshn,1), 1), 'constant');

% RMS scale to match the HINT-Noise
white_noise_scale = rms(hint_spshn(:,1))./rms(white_noise); 
white_noise = white_noise .* white_noise_scale;

% Duplicate channels
white_noise = [white_noise white_noise]; 

% Write to file 
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-white_noise.wav'), white_noise, FS, 'BitsperSample', audio_bit_depth);

%% CREATE HINT + SPEECH SHAPED NOISE (SPSHN) STIMULI
% ===================================
% Here, we create the HINT + SPSHN corpus. Here are the approximate
% procedures and rationale.
%
%   1. Load all original HINT sentence waveforms.
%   2. Remove silent periods from beginning and end of waveforms.
%   3. Temporally concatenate all waveforms
%
% Steps 1 - 3 result in a large acoustic waveform that can be used to
% estimate the long-term spectrum of the HINT speech corpus.
%
%   4. Reshape the spectrum of the white noise sample above to match the
%   long-term spectrum of the HINT corpus. Spectral matching is done a
%   multi-step process here. 
%
%       - Match spectra from [125 inf]. This creates a spectrally matched 
%         noise sample that has NOT been bandpass filtered yet. In other
%         words, we're just matching the overall spectral shape. This
%         allows us to pass in a spectrally matched noise sample into
%         SIN_CalAudio, which does RMS scaling to match the RMS of noise
%         masker and target speech. 
%
%       - Bandpass filter the noise sample (and all stimuli). Also RMS
%       scale them to match. These steps are handled in SIN_CalAudio.m.
%
%   5. Add SPSHN to the HINT sentences. 
%
% Steps 4 - 5 result in two-channel wav files. The first channel is the
% speech track and the second is the noise track. These can then be mixed
% using player_main's mixer.
%
%   6. Spectral checking. The calibrated stimuli are then reloaded from
%   file, thresholded, and temporally concatenated as done above. The
%   long-term spectra is then compared to the spectrally-matched noise
%   sample. A figure is generated with this summary information.
%
%   7. The SPL of the sounds are compared at a digital level using RMS. A
%   plot is also generated. 
%
%   8. Create a lookup table for the calibrated stimuli. This is an XLSX
%   spreadsheet. 
% ===================================

% Get a list of HINT sentences using SIN functions
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{2}.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Load the white noise file
%   Note that the hint_sps
[hint_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-white_noise.wav')); 
% [hint_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Just use channel 1 of hint_spshn
hint_spshn = hint_spshn(:,1); 

% Concatenate the HINT Corpus
[hint_time_series, hint_fs] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh, ...
    'mixer', [0;1]); 

% sample rate check
if spshn_fs ~= FS, error('Mismatched sample rates'); end 

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
    'bitrate',  audio_bit_rate, ...
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
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '');
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
plot_psd({ hint_time_series hint_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
legend('HINT Sentences', 'HINT SPSHN')
title('HINT Spectra'); 

% Check RMS levels
figure
plot(db([rms(hint_time_series) rms(hint_spshn)]), 's', 'linewidth', 2)
ylabel('RMS (dB)'); 
title('HINT / SPSHN relative levels'); 

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
% The procedure used to create the HINT + ISTS stimuli is similar to the
% procedure used to create the HINT + SPSHN stimuli above, but there are
% important differences. Below is an approximate outline of the procedures
% CWB devised.
%
%   1. Load the original ISTS stimulus provided by Wu and also downloaded
%   from the web.
%
%   2. Bandpass filter the ISTS stimulus. Again, we're only interested in
%   the range from 125 - 10,000 Hz. So Apply the bandpass filter here.
%
%   3. Match the spectrum of the ISTS stimulus to concatenated,
%   bandpass-filtered HINT corpus. 
%
%   4. RMS scale the now spectrally matched ISTS track to match the
%   calibration stimulus (hint spshn). 
%
% The result from 1 - 4 is a *single channel* ISTS stimulus that is
% spectrally matched to the HINT corpus. It is also RMS-scaled to ~0 dB
% SPL. 
%
%   5. Remix the single-channel ISTS to make a 4-channel,
%   spectrally-matched ISTS stimulus for the HINT. 
%
% The result of 5 is a 4-channel ISTS stimulus. Each channel should be
% spectrally matched and RMS scaled to ~0 dB SPL. Thus, if these are
% combined in some way (e.g., combining across the 4-channels to make a
% single-channel, 4-talker babble), then we have to account for the
% dB SPL changes caused by remixing the audio.
%
%   6. Add ISTS noise track to HINT stimuli. This is done by collapsing the
%   4-channel ISTS babble into a single channel file. During the noise
%   addition process, we rescale each of the 4 ISTS channels such that
%   their SUM will be ~0 dB SPL. 
%
% The result of 6 is a two-channel audio stimulus. Track 1 is the HINT
% sentence. Track 2 is the 4-talker ISTS babble. 
%
%   7. PSDs are plotted with the HINT speech tracks, 4-talker ISTS, and the
%   SPSHN tracks. ISTS/SPSHN tracks are loaded FROM the files produced in
%   6, so this is a good check, CWB thinks. However, the spectra might
%   differ slightly due to the windowing (fade in/out) introduced to the
%   noise tracks during step 6. 
%
%   8. Create a HINT lookup table for the ISTS stimuli. 
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
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT_ISTS_1_talker;bandpass;0dB.wav'), ists_filt, hint_fs, 'BitsperSample', audio_bit_depth);

% Make 4-talker ISTS
%   Note that the timing offsets were selected through some trial and error
%   by CWB. His goal was to minimize temporal gaps (that is, periods of
%   relative silence) when summing the signal over channels.
ists_4talker = remixaudio(ists_filt, ...
    'fsx',    hint_fs, ...
    'mixer',    [1 1 1 1], ...
    'toffset',  [0 11.234 28.1987 46], ...
    'writetofile',  false); 

% Confirm that RMS is the same for all channels relative to the calibration
% file
[db(rms(ists_4talker)) db(rms(ists_filt))] - db(rms(hint_spshn))

% Write the 4-talker version
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT_ISTS_4_talker;bandpass;0dB.wav'), ists_4talker, hint_fs, 'BitsperSample', audio_bit_depth);

% Need to calculate the scaling factor that needs to be applied to each
% of the ISTS channels (talkers) to collapse them into a single channel. 
ists_scale4hint = rms(hint_spshn)./rms(sum(ists_4talker,2));

% Add ISTS noise to HINT stimuli
%   nmixer is DxP, where D is the number of channels in the wav file and P
%   is the number of output channels 
addnoise2HINT(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT_ISTS_4_talker;bandpass;0dB.wav'), ...
    'testID', 'HINT (SNR-50, SPSHN)', ...
    'wav_regexp', '[0-9]{2};bandpass;0dB.wav$', ...
    'tmixer', [1 0], ...
    'nmixer', [ [zeros(size(ists_4talker,2),1)] [ones(size(ists_4talker,2),1).*ists_scale4hint] ], ...
    'leadlag', [1 1], ...
    'suffix', '+4talker_ists', ...
    'noiserange', [0 60], ...
    'bitdepth', audio_bit_depth, ...
    'removesilence', true, ...
    'ampthresh', hint_ampthresh*hint_scale, ...
    'random_noise_seed', str2double(hint_random_noise_seed)); % seed with subject identifier. hard-coded here, but will wrap this into a function later.

% Re-read in the HINT speech tracks, ISTS, and SPSHN from the noise-mixed
% files to confirm that our spectral matching is as good as we think it is.
% This will be approximate due to thresholding at beginning and end of
% sounds. 
opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB[+]spshn.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Concatenate the HINT Corpus
[spshn] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', [0; 1]);

% Read in 4-talker ISTS
opts.specific.wav_regexp = '[0-9]{2};bandpass;0dB[+]4talker_ists.wav$';

% Get the file names and massage them into a useful format.
[~, hint_audio_files] = SIN_stiminfo(opts); 
hint_audio_files = concatenate_lists(hint_audio_files); 

% Concatenate the HINT Corpus
[ists] = concat_audio_files(hint_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', [0; 1]);

% clear ists_filt ists
% [ists, ists_fs] = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT_ISTS_4_talker;bandpass;0dB.wav'));

if ists_fs ~= FS, error('Mismatched sample rates'); end 

% Plot PSDs of calibrated files
plot_psd({ hint_time_series hint_spshn spshn ists }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
legend('Concatenated Sentences', 'SPSHN', 'SPSHN from HINT Files', 'ISTS from HINT files', 'location', 'NorthOutside')
title('HINT PSDs')
set(gca, 'XScale', 'log')
ylabel('PSD (dB/Hz)');
xlabel('Frequency (Hz)');
grid on

% Compute decibel differences between the concatenated HINT corpus, SPSHN,
% and ISTS
figure
plot(1, [db(rms(hint_time_series)) db(rms(hint_spshn)) db(rms(spshn)) db(rms(ists))], 's')
legend('Concatenated Sentences', 'SPSHN', 'SPSHN from HINT Files', 'ISTS from HINT files', 'location', 'NorthOutside')
ylabel('dB')
title('Relative HINT Stimulus Levels'); 

% Create HINT Lookup
createHINTlookup(';bandpass;0dB+4talker_ists');

%% ACCEPTABLE NOISE LEVEL (ANL) CALIBRATION
% ===================================
% The ANL calibration is relatively simple by comparison to the HINT
% calibration code. Here's an approximate step-by-step procedure.
%
%   1. Load original ANL file. This is actually a STEREO file. The first
%   track is the target discourse track. Track 2 is the masker
%   (multi-talker babble) track.
%
%   2. Bandpass filter both channels of the ANL. Again, we're only
%   interested in the 125 - 10kHz range, so filter the stimuli.
%
%   3. Match the RMS between ANL channels. CWB noted that the RMS levels
%   between the target and masker tracks differ by ~0.49 dB (masker track
%   louder than target track). While having these two values strictly
%   matched will not affect ANL estimates (this is a relative measure
%   anyway), CWB opted to RMS scale the masker track to match the RMS of
%   the target track. 
%
%   4. Match ANL to calibration sound (That's the spshn noise track from
%   HINT). 
%
%   5. Write the ANL track.
%
% The result of 1 - 5 is a two-channel track. Note that CWB did *not* do
% any spectral matching of any kind here. The rationale is that the ANL
% stimulus is a stock stimulus that should be used as is to the degree
% possible. So CWB limited filtering to a bandpass filter. 
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

% Plot RMS estimates for each anl channel.
%   We don't care so much about the spectral composition because we aren't
%   trying to match that to anything in this case. 
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
%
% CWB still unsure about this ... probably will only make minor
% differences and will require a far more complex procedure, but probably
% smart to do it this way, especially when the concatenated stimuli are
% *shorter* in duration ultimately than the noise stimulus. If the stimulus
% is not stionary (e.g., with the ISTS), then we're going to introduce
% errors into the spectral matching procedure. 
% ===================================

% Select a subset of HINT sentences
%   Use the first N sentences in the corpus, where N is determined by
%   hagerman_sentence_number above. 
opts = SIN_TestSetup('HINT (SNR-50, SPSHN)', '');
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
%   We want to basically start over so we aren't filtering this noise file
%   more than the one used for HINT. If we started with the completed
%   version of HINT-SPSHN and filtered that, then our filter order would be
%   twice what we expect it to be here. So some recreating the wheel is
%   necessary. 
[hagerman_spshn, hagerman_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-white_noise.wav')); 

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
%   Should evaluate to ~ 0 dB. 
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


% Get pwelch for concatenated hint sentences
% [Pxx, pwelch_freqs] = pwelch(hagerman_time_series, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for speech shaped noise sample
% P_spshn = pwelch(hagerman_spshn_filt, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% Get pwelch for ISTS
% P_ists = pwelch(hagerman_ists_filt, pwelch_window, pwelch_noverlap, pwelch_nfft, hint_fs); 

% figure, hold on
% plot(pwelch_freqs, db([Pxx P_spshn P_ists], 'power'), 'linewidth', 1.5)
% legend('Concatenated Sentences', 'SPSHN', 'ISTS', 'location', 'NorthOutside')
% title('Hagerman PSDs')
% set(gca, 'XScale', 'log')
% ylabel('PSD (dB/Hz)');
% xlabel('Frequency (Hz)');
% grid on

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

% ===================================
% Confirm that the Hagerman speech and noise tracks are well matched both
% spectrally and in terms of dB SPL.
%   - The safest way to check the noise tracks is to load them directly
%   from the written files and run the spectral analysis on THOSE data.
%   Recall that the noise samples may necessarily be repeated in
%   createHagerman to create a noise track that is sufficiently long enough
%   for the target speech track. 
% ===================================

% Load the hagerman spshn track from one of the files
opts = SIN_TestSetup('Hagerman (Unaided, SPSHN)', '2999'); 

% Change wav file filter to get just ONE file
opts.specific.wav_regexp = 'spshn;bandpass;0dB;00dB SNR;TinvNinv.wav$';
[~, hagerman_spshn_files] = SIN_stiminfo(opts); 
hagerman_spshn_files = concatenate_lists(hagerman_spshn_files); 

% Read in the first noise track
hagerman_spshn = concat_audio_files(hagerman_spshn_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', [0;1;1;1;1;0]); 

% Read in ISTS
opts.specific.wav_regexp = 'ists;bandpass;0dB;00dB SNR;TinvNinv.wav$';
[~, hagerman_ists_files] = SIN_stiminfo(opts); 
hagerman_ists_files = concatenate_lists(hagerman_ists_files); 

% Read in the first noise track
hagerman_ists = concat_audio_files(hagerman_ists_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', hint_ampthresh.*hint_scale, ...
    'mixer', [0;1;1;1;1;0]); 

% Plot PSDs of calibrated files
plot_psd({ hagerman_time_series hagerman_spshn hagerman_spshn_filt hagerman_ists }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
legend('Concatenated Sentences', 'SPSHN from Files', 'SPSHN', 'ISTS from Files', 'location', 'NorthOutside')
title('Hagerman PSDs')
set(gca, 'XScale', 'log')
ylabel('PSD (dB/Hz)');
xlabel('Frequency (Hz)');
grid on

%% MLST CLEANUP
%   There are two lists that have 13 stimuli instead of 12. CWB contacted
%   Ginny Driscoll on October 29, 2014 and inquired about these additional
%   files. The additional files are filtered out in their software rather
%   than deleted manually. We won't have that luxury, so we need to delete
%   the files. We need to delete or otherwise rename the following files:
%
%       List_09\9_T6_237_LS.mp4/mp3
%       List_12\12_T3_309_LD.mp4/mp3
%
%   CWB decided to go with renaming rather than deleting in case we need
%   the files later. 
!move "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_09\9_T6_237_LS.mp4" "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_09\9_T6_237_LS_DONOTUSE.mp4"
!move "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_09\9_T6_237_LS.mp3" "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_09\9_T6_237_LS_DONOTUSE.mp3"

!move "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_12\12_T3_309_LD.mp4" "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_12\12_T3_309_LD_DONOTUSE.mp4"
!move "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_12\12_T3_309_LD.mp3" "C:\Users\Public\GitHub\SIN\playback\MLST (adult)\List_12\12_T3_309_LD_DONOTUSE.mp3"

%% CREATE MLST + SPEECH SHAPED NOISE (SPSHN) STIMULI (65 dB and 80 dB)
%   Ultimately, we need a single channel speech track + an single-channel
%   speech shaped noise track (SPSHN). The calibration procedure should be
%   identical to the HINT calibration procedure above, just with different
%   stimuli. 

% ===================================
% 65 dB
%   The code below creates the SPSHN sample and creates the 0 dB stimuli
%   for use in the 65 dB/+8 dB SNR condition. 
% ===================================

% ===================================
% Match the long-term spectrum of the spshn spectrum to the long-term
% spectrum of the concatenated HINT corpus
% ===================================

% Get a list of MLST sentences using SIN functions
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', '');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% original MP4s
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$';

% Get the file names and massage them into a useful format.
[~, mlst_audio_files] = SIN_stiminfo(opts); 
mlst_audio_files = concatenate_lists(mlst_audio_files); 

% mlst_audio_files = {mlst_audio_files{(cellfun(@isempty, strfind(mlst_audio_files, 'C:\Users\Public\GitHub\SIN\playback\MLST (Adult)\List_06\2_T9_060_HS.mp4')))}}';

% Load the speech shaped noise file
% warning('Changed SPSHN sample')
[mlst_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-white_noise.wav')); 
% [mlst_spshn, spshn_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'HINT-Noise.wav')); 

% Just use channel 1 of mlst_spshn
mlst_spshn = mlst_spshn(:,1); 

% Concatenate the HINT Corpus
[mlst_time_series, mlst_fs] = concat_audio_files(mlst_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh, ...
    'mixer', [0;1]); 

% if max(max(abs(mlst_time_series))) > 1, error('Value out of range'); end

% Resample MLST time series
%   MLST stimuli are written at 48 kHz, so we have to resample to match the
%   44.1 kHz sampling rate of all other stimuli.
mlst_time_series = resample(mlst_time_series, FS, mlst_fs); 
mlst_fs = mlst_fs .* (FS./mlst_fs); % reset this just in case I use it by accident below

% sample rate check
if mlst_fs ~= FS, error('Mismatched sample rates'); end 

% We need to create a SPSHN stimulus that is spectrally-matched to the MLST
% speech corpus (concatenated sentences). We just need to spectrally match
% in a high-pass sense. We don't bandpass filter here because bandpass
% filtering is implicitly done in the call to SIN_CalAudio below. 
[mlst_spshn] = match_spectra(mlst_time_series, mlst_spshn, ...
        'fsx', FS, ...
        'fsy', FS, ...
        'plot', true, ...
        'frequency_range', [filter_frequency_range(1) inf], ... % only work on the higher frequencies.
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);

% Need to bandpass filter the mlst_spshn prior to scaling it to match the 
% RMS of the calibration file
mlst_spshn_filt = filtfilt(b, a, mlst_spshn); 

% Match MLST-SPSHN.wav to calibration file
hint_spshn = SIN_loaddata(calibration_file); 
mlst_scale = rms(hint_spshn)./rms(mlst_spshn_filt); 
mlst_spshn_filt = mlst_spshn_filt .* mlst_scale; 

% Also apply the scaling factor to mlst_spshn (the non-bandpass filtered
% stimulus)
%   Note that mlst_spshn will be slightly louder (larger RMS) than its
%   bandpass filtered counter part. We'll use this file below 
mlst_spshn = mlst_spshn .* mlst_scale;

% Print comparative decibel levels
%   The second element should evaluate to ~0 dB. The first element may
%   differ slightly (typically will be slightly larger) at time of running,
%   CWB notes the vector is [0.2517 0], as expected
[db(rms(mlst_spshn)) db(rms(mlst_spshn_filt))] - db(rms(hint_spshn))

% Write the non-bandpass filtered MLST SPSHN sample
%   This will be used as a reference below in calls to SIN_CalAudio because
%   SIN_CalAudio implicitly bandpass filters (and writes) the reference
%   stimulus. So we want to feed SIN_CalAudio the non-bandpass filtered
%   stimulus to begin with. 
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), mlst_spshn, FS, 'BitsperSample', audio_bit_depth);
% audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN;bandpass.wav'), mlst_spshn_filt, FS, 'BitsperSample', audio_bit_depth);

% Using the spectrally matched SPSHN sample above, calibrate the whole
% corpus. 
mlst_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), ...
    'testID', 'MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', ...
    'nmixer', db2amp(0), ... % We don't want to scale the noise file at all since it is already RMS scaled to calibration levels. 
    'targetdB', 0, ... % Set levels to match the reference sound. 
    'removesilence', true, ...
    'ampthresh', mlst_ampthresh, ... 
    'bitdepth', audio_bit_depth, ...
    'bitrate',  audio_bit_rate, ...
    'suffix', ';bandpass;0dB_UW', ... % append UW so we know these are for UW's setup
    'tmixer', [0;1], ...
    'omixer', [1 0], ...
    'writeref', true, ...
    'wav_regexp',  '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order, ...
    'overwritemp4', true);

mlst_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), ...
    'testID', 'MLST (Audio, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', ...
    'nmixer', db2amp(0), ... % We don't want to scale the noise file at all since it is already RMS scaled to calibration levels. 
    'targetdB', 0, ... % Set levels to match the reference sound. 
    'removesilence', true, ...
    'ampthresh', mlst_ampthresh, ... 
    'bitdepth', audio_bit_depth, ...
    'bitrate',  audio_bit_rate, ...
    'suffix', ';bandpass;0dB_UofI', ... % append UofI to file names so we know these are specific to University of Iowa.
    'tmixer', [0;1], ...
    'omixer', [0 1], ...    % we changed the output mapping so the speech track will play from speaker 8 (0 degree azimuth)
    'writeref', true, ...
    'wav_regexp',  '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order, ...
    'overwritemp4', true);

% Load all MLST files and figure out if any of them have large values in
% them. IF they do, then use the wav files to write the audio tracks

% Check SPSHN (UW)
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', '1001');
opts = opts(1);
[~, mlst_av_files] = SIN_stiminfo(opts);
mlst_av_files = concatenate_lists(mlst_av_files); 

bad_mlst_files = {};
for i=1:numel(mlst_av_files)
    
    time_series = SIN_loaddata(mlst_av_files{i}); 
    
    % Check for clipping 
    %   If we encounter clipping, this indicates that there was weird
    %   filtering artifacts during encoding process. Post the file to the
    %   screen and keep track of them. 
    if max(max(abs(time_series))) > 1
        bad_mlst_files{end+1} = mlst_av_files{i}; 
        display(mlst_av_files{i});
    end % if max(max
    
end % for i=1:numel(mlst_av_files)

opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', '2001'); % gets the UofI files
opts = opts(1);
[~, mlst_av_files] = SIN_stiminfo(opts);
mlst_av_files = concatenate_lists(mlst_av_files); 

for i=1:numel(mlst_av_files)
    
    time_series = SIN_loaddata(mlst_av_files{i}); 
    
    % Check for clipping 
    if max(max(abs(time_series))) > 1
        bad_mlst_files{end+1} = mlst_av_files{i}; 
    end % if max(max
    
end % for i=1:numel(mlst_av_files)

% This bit of code will fix these wonky files by reencoding them using the
% WAV file's audio track. This leads to *slightly* different audio tracks
% normally, but this is better than having really weird transients. 
for i=1:numel(bad_mlst_files)
    
    % Need to get the original file name for the conversion below
    [PATHSTR, NAME, EXT] = fileparts(bad_mlst_files{i}); 
    NAME = NAME(1:findstr(NAME, ';bandpass;')-1); 
    
    orig_file = fullfile(PATHSTR, [NAME EXT]); 
    
    cmd = ['ffmpeg -y -i "'...
    orig_file '" -i "' strrep(bad_mlst_files{i}, '.mp4', '.wav')...
                    '" -map 0:0 -map 1 "' bad_mlst_files{i} '"'];

    system(cmd, '-echo'); 
end % for i=:numel(bad_mlst_files)

% Plot PSD and levels
%   Before we do this, we'll want to reload all of the data from file, just
%   in case there's some wonkiness in the way the files are written.
% Get the file names and massage them into a useful format.

% Get a list of MLST sentences using SIN functions
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 65 dB SPL, +8 dB SNR)', '');
opts = opts(1);

% Grab the bandpass noise files 
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UW.mp4$';

[~, mlst_mp4_files] = SIN_stiminfo(opts); 
mlst_mp4_files = concatenate_lists(mlst_mp4_files); 

% remove a botched file
% mlst_mp4_files = {mlst_mp4_files{(cellfun(@isempty, strfind(mlst_mp4_files, 'C:\Users\Public\GitHub\SIN\playback\MLST (Adult)\List_06\2_T9_060_HS;bandpass;0dB.mp4')))}}';

% Concatenate the MLST Corpus
[mlst_mp4_time_series, mlst_fs] = concat_audio_files(mlst_mp4_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% sample rate check
if mlst_fs ~= FS, error('Mismatched sample rates'); end 

% Check temporal alignment of first and last file. 
%   Recall that mlst_audio_files is still the ORIGINAL MP4s. So realign the
%   first and last pair of files to make sure we've done a good job.
%
%   This step allows us to verify that we haven't screwed up our AV
%   alignment through any processing steps of our own along the way. 
new_data = SIN_loaddata(mlst_mp4_files{1}); 
new_data = new_data(:,1); 
orig_data = SIN_loaddata(mlst_audio_files{1}); 
orig_data = orig_data(:,1).*mlst_scale; % use scaling factor to make comparisons easier

align_timeseries(orig_data, new_data, 'xcorr', 'pflag', 2, 'fsx', 48000, 'fsy', FS); 

new_data = SIN_loaddata(mlst_mp4_files{end}); 
new_data = new_data(:,1); 
orig_data = SIN_loaddata(mlst_audio_files{end}); 
orig_data = orig_data(:,1).*mlst_scale; % use scaling factor to make comparisons easier

align_timeseries(orig_data, new_data, 'xcorr', 'pflag', 2, 'fsx', 48000, 'fsy', FS); 

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
%
%   Again, just load the UW version since the UofI is identical, except teh
%   channels are mapped differently
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UW.wav$';

[~, mlst_audio_files] = SIN_stiminfo(opts); 
mlst_audio_files = concatenate_lists(mlst_audio_files); 
% mlst_audio_files = {mlst_audio_files{(cellfun(@isempty, strfind(mlst_audio_files, 'C:\Users\Public\GitHub\SIN\playback\MLST (Adult)\List_06\2_T9_060_HS;bandpass;0dB.wav')))}}';

% Concatenate the HINT Corpus
[mlst_audio_time_series, mlst_fs] = concat_audio_files(mlst_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% Load the (calibrated and filtered) MLST SPSHN track
%   Have to load the UW specific version, then rewrite to general file.
mlst_spshn = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN;bandpass;0dB_UW.wav'));
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN;bandpass;0dB.wav'), mlst_spshn, FS, 'BitsperSample', audio_bit_depth); 
mlst_spshn = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN;bandpass;0dB.wav'));

% Create the 4 channel version and write it to file
%   Use the same temporal offsets here. 
mlst_spshn_4channel = remixaudio(mlst_spshn, ...
    'fsx',    FS, ...
    'mixer',    [1 1 1 1], ...
    'toffset',  [0 11.234 28.1987 46], ...
    'writetofile',  false); 
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_SPSHN_4_channel;bandpass;0dB.wav'), mlst_spshn_4channel, FS, 'BitsperSample', audio_bit_depth);

% Read the 4-channel version back in from disk to account for any writing
% precision errors
[mlst_spshn_4channel, mlst_fs] = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_SPSHN_4_channel;bandpass;0dB.wav'));

% Check sampling rate
if mlst_fs ~= FS, error('Sample rate mismatched'); end 

plot_psd({ mlst_audio_time_series mlst_mp4_time_series mlst_spshn_4channel(:,1) mlst_spshn_4channel(:,2) mlst_spshn_4channel(:,3) mlst_spshn_4channel(:,4)}, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
title('0 dB MLST');
legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

% Plot RMS levels
%   These should be very close to identical. CWB noticed that the MP4s are
%   slightly quieter (49.1142 vs 49.0327 dB). Not perfect, but not terrible
%   either. Can spend some time on this if we need to later. 
figure, hold on
plot(1, [db(rms(mlst_audio_time_series)) db(rms(mlst_mp4_time_series)) db(rms(mlst_spshn(:,1)))], 's')
legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

% ===================================
% 75 dB
%   The code below creates the SPSHN sample and creates the +15 dB stimuli
%   for use in the 75 dB/+0 dB SNR condition. 
% ===================================

%% CREATE MLST + SPEECH SHAPED NOISE (SPSHN) STIMULI (75 dB)
%   Ultimately, we need a single channel speech track + an single-channel
%   speech shaped noise track (SPSHN). The calibration procedure should be
%   identical to the HINT calibration procedure above, just with different
%   stimuli. 
%
%   We'll want to use the non-bandpass filtered version of MLST SPSHN since
%   bandpass filtering will be done implicitly below. 
mlst_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), ...
    'testID', 'MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', ...
    'nmixer', db2amp(0), ... % We don't want to scale the noise file at all since it is already RMS scaled to calibration levels. 
    'targetdB', +10, ... % Set levels to match the reference sound. 
    'removesilence', true, ...
    'ampthresh', mlst_ampthresh, ... 
    'bitdepth', audio_bit_depth, ...
    'bitrate',  audio_bit_rate, ...
    'suffix', ';bandpass;+10dB_UW', ...
    'tmixer', [0;1], ...
    'omixer', [1 0], ...
    'writeref', true, ...
    'wav_regexp',  '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order, ...
    'overwritemp4', true);

% Do the same thing, but change mapping for UofI.
mlst_scale = SIN_CalAudio(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN.wav'), ...
    'testID', 'MLST (Audio, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', ...
    'nmixer', db2amp(0), ... % We don't want to scale the noise file at all since it is already RMS scaled to calibration levels. 
    'targetdB', +10, ... % Set levels to match the reference sound. 
    'removesilence', true, ...
    'ampthresh', mlst_ampthresh, ... 
    'bitdepth', audio_bit_depth, ...
    'bitrate',  audio_bit_rate, ...
    'suffix', ';bandpass;+10dB_UofI', ...
    'tmixer', [0;1], ...
    'omixer', [0 1], ...
    'writeref', true, ...
    'wav_regexp',  '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp4$', ...
    'apply_filter', true, ...
    'filter_type', filter_type, ...
    'frequency_cutoff', filter_frequency_range, ...
    'filter_order', bandpass_filter_order, ...
    'overwritemp4', true);

% Check SPSHN (UW)
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', '1001');
opts = opts(1);
[~, mlst_av_files] = SIN_stiminfo(opts);
mlst_av_files = concatenate_lists(mlst_av_files); 

bad_mlst_files = {};
for i=1:numel(mlst_av_files)
    
    time_series = SIN_loaddata(mlst_av_files{i}); 
    
    % Check for clipping 
    if max(max(abs(time_series))) > 1
        bad_mlst_files{end+1} = mlst_av_files{i}; 
    end % if max(max
    
end % for i=1:numel(mlst_av_files)

opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', '2001'); % gets the UofI files
opts = opts(1);
[~, mlst_av_files] = SIN_stiminfo(opts);
mlst_av_files = concatenate_lists(mlst_av_files); 

for i=1:numel(mlst_av_files)
    
    time_series = SIN_loaddata(mlst_av_files{i}); 
    
    % Check for clipping 
    if max(max(abs(time_series))) > 1
        bad_mlst_files{end+1} = mlst_av_files{i}; 
    end % if max(max
    
end % for i=1:numel(mlst_av_files)

% This bit of code will fix these wonky files by reencoding them using the
% WAV file's audio track. This leads to *slightly* different audio tracks
% normally, but this is better than having really weird transients. 
for i=1:numel(bad_mlst_files)
    
    % Need to get the original file name for the conversion below
    [PATHSTR, NAME, EXT] = fileparts(bad_mlst_files{i}); 
    NAME = NAME(1:findstr(NAME, ';bandpass;')-1); 
    
    orig_file = fullfile(PATHSTR, [NAME EXT]); 
    
    cmd = ['ffmpeg -y -i "'...
    orig_file '" -i "' strrep(bad_mlst_files{i}, '.mp4', '.wav')...
                    '" -map 0:0 -map 1 "' bad_mlst_files{i} '"'];

    system(cmd, '-echo'); 
end % for i=:numel(bad_mlst_files)

% Get a list of MLST sentences using SIN functions
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', '');
opts = opts(1);

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;[+]10dB_UW.mp4$';

[~, mlst_mp4_files] = SIN_stiminfo(opts); 
mlst_mp4_files = concatenate_lists(mlst_mp4_files); 

% Concatenate the MLST Corpus
[mlst_mp4_time_series, mlst_fs] = concat_audio_files(mlst_mp4_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% Change the regular expression used to search for audio files; we want the
% files that do NOT have the noise added to the second channel. 
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;[+]10dB_UW.wav$';

[~, mlst_audio_files] = SIN_stiminfo(opts); 
mlst_audio_files = concatenate_lists(mlst_audio_files); 

% Concatenate the HINT Corpus
[mlst_audio_time_series, mlst_fs] = concat_audio_files(mlst_audio_files, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% Load the (calibrated and filtered) MLST SPSHN track
% mlst_spshn = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST-SPSHN;bandpass;0dB.wav'));
[mlst_spshn_4channel] = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_SPSHN_4_channel;bandpass;0dB.wav'));

% plot_psd({ mlst_audio_time_series mlst_mp4_time_series mlst_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
plot_psd({ mlst_audio_time_series mlst_mp4_time_series mlst_spshn_4channel(:,1) mlst_spshn_4channel(:,2) mlst_spshn_4channel(:,3) mlst_spshn_4channel(:,4)}, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
title('+10dB MLST');
legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

% Plot RMS levels
%   These should be very close to identical. CWB noticed that the MP4s are
%   slightly quieter (49.1142 vs 49.0327 dB). Not perfect, but not terrible
%   either. Can spend some time on this if we need to later. 
figure, hold on
plot(1, [db(rms(mlst_audio_time_series)) db(rms(mlst_mp4_time_series)) db(rms(mlst_spshn_4channel))], 's')
legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

% =================
% Create lookup tables for MLST SPSHN
%   Need separate lookup talbes for 0 dB and +15 dB case
% =================
createMLSTlookup('suffix', ';bandpass;0dB_UW', 'testID', 'MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', 'wav_regexp', '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UW.mp4$');
createMLSTlookup('suffix', ';bandpass;0dB_UofI', 'testID', 'MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', 'wav_regexp', '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UofI.mp4$');
createMLSTlookup('suffix', ';bandpass;+10dB_UW', 'testID', 'MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', 'wav_regexp', '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;[+]15dB_UW.mp4$');
createMLSTlookup('suffix', ';bandpass;+10dB_UofI', 'testID', 'MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', 'wav_regexp', '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;[+]15dB_UofI.mp4$');

%% CREATE MLST + 4-talker ISTS STIMULI (65 dB and 80 dB)
%   Ultimately, we need a single channel speech track + 4 channels of the
%   ISTS. Recall that we will use the SAME speech track materials (mp4 and
%   wav files made for speech shaped noise version). All we need to make
%   that's "new" is a 4-channel ISTS stimulus. 

% Load original ISTS
[ists, ists_fs] = SIN_loaddata((fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'ISTS-V1.0_60s_24bit.wav'))); 

if ists_fs ~= FS, error('sampling rates differ'); end

% Band pass filter ISTS 
[b, a] = butter(bandpass_filter_order, filter_frequency_range./(FS/2), filter_type);
ists_filt = filtfilt(b, a, ists);

% Match ISTS to concatenated MLST corpus
%   Use the WAV files rather than the MP4s since the MP4s seem to introduce
%   some error in the spectral properties. This is something we'll need to
%   address. 
[ists_filt] = match_spectra(mlst_audio_time_series, ists_filt, ...
        'fsx', FS, ...
        'fsy', FS, ...
        'plot', true, ...
        'frequency_range', [eps inf], ... % excludes DC component
        'filter_order', spectral_match_filter_order, ...
        'window', pwelch_window, ...
        'noverlap', pwelch_noverlap, ...
        'nfft', pwelch_nfft);
    
% Need to RMS scale the filtered ISTS to match our calibration stimulus.
% This will produce a single-channel, 1-talker ISTS stimulus that is
% calibrated to ~0 dB relative to the calibration stimulus. 
hint_spshn = SIN_loaddata(calibration_file);
ists_scale = rms(hint_spshn) ./ rms(ists_filt);
ists_filt = ists_filt .* ists_scale;

% Write spectrally matched/calibrated ISTS for HINT
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_ISTS_1_talker;bandpass;0dB.wav'), ists_filt, FS, 'BitsperSample', audio_bit_depth);

% Make 4-talker ISTS
%   Note that the timing offsets were selected through some trial and error
%   by CWB. His goal was to minimize temporal gaps (that is, periods of
%   relative silence) when summing the signal over channels.
mlst_ists_4talker = remixaudio(ists_filt, ...
    'fsx',    FS, ...
    'mixer',    [1 1 1 1], ...
    'toffset',  [0 11.234 28.1987 46], ...
    'writetofile',  false); 

% Confirm that RMS is the same for all channels relative to the calibration
% file
[db(rms(mlst_ists_4talker))] - db(rms(hint_spshn))

% Write the 4-talker version
%   Note that each channel of the ISTS should be calibrated to ~ 0 dB. So,
%   we will need to apply a correction factor to the mod_mixer during sound
%   playback to account for multiple speaker playback. 
audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_ISTS_4_talker;bandpass;0dB.wav'), mlst_ists_4talker, FS, 'BitsperSample', audio_bit_depth);

% Read 4-talker version in from disk to account for precision errors
[mlst_ists_4talker] = audioread(fullfile(fileparts(which('runSIN')), 'playback', 'Noise', 'MLST_ISTS_4_talker;bandpass;0dB.wav'));

% Estimate the correction factor for ISTS playback
mlst_ists_correction_db = db(rms(hint_spshn)./rms(sum(mlst_ists_4talker,2)))

% Get a list of MLST sentences using SIN functions
opts = SIN_TestSetup('MLST (AV, Aided, SPSHN, 75 dB SPL, +0 dB SNR)', '');
opts = opts(1);

% Just grab the UW files - U of I are identical, just with the channels
% swapped. 
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UW.mp4$';

[~, mlst_mp4_files_0dB] = SIN_stiminfo(opts); 
mlst_mp4_files_0dB = concatenate_lists(mlst_mp4_files_0dB); 

% Concatenate the MLST Corpus
[mlst_mp4_time_series_0dB, mlst_fs] = concat_audio_files(mlst_mp4_files_0dB, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% Again, just grab the UW files. UofI should be identical, but have a
% different channel mapping (so the mixer settings would need to change)
opts.specific.wav_regexp = '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS];bandpass;0dB_UW.wav$';

[~, mlst_audio_files_0dB] = SIN_stiminfo(opts); 
mlst_audio_files_0dB = concatenate_lists(mlst_audio_files_0dB); 

% Concatenate the HINT Corpus
[mlst_audio_time_series_0dB, mlst_fs] = concat_audio_files(mlst_audio_files_0dB, ...
    'remove_silence', true, ...
    'amplitude_threshold', mlst_ampthresh.*mlst_scale, ...
    'mixer', [1;0]); 

% Plot sanity checks
% plot_psd({ mlst_audio_time_series mlst_mp4_time_series mlst_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
% plot_psd({ mlst_audio_time_series mlst_mp4_time_series mlst_ists_4talker(:,1) mlst_ists_4talker(:,2) mlst_ists_4talker(:,3) mlst_ists_4talker(:,4)}, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
% title('MLST, ISTS');
% legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

% plot_psd({ mlst_audio_time_series mlst_mp4_time_series_0dB mlst_spshn }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
plot_psd({ mlst_audio_time_series_0dB mlst_mp4_time_series_0dB mlst_audio_time_series mlst_mp4_time_series mlst_spshn_4channel(:,1) mlst_ists_4talker(:,1) }, @pwelch, pwelch_window, pwelch_noverlap, pwelch_nfft, FS); 
title('MLST PSD');
legend('MLST WAV Files (0dB)', 'MLST MP4 Files (0dB)', 'MLST WAV Files (+15dB)', 'MLST MP4 Files (+15dB)', 'MLST SPSHN', 'MLST ISTS', 'location', 'EastOutside')

% Plot RMS levels
%   This is not spot on for anything yet ... we're off by ~0.5 dB for the
%   audio and MP4 files of the 0dB MLST files. The rest are close. Not sure
%   why we're seeing the discrepancy for those ... will need to work on it.
figure, hold on
plot(1, [db(rms(mlst_audio_time_series_0dB)) db(rms(mlst_mp4_time_series_0dB)) db(rms(mlst_audio_time_series)) db(rms(mlst_mp4_time_series)) db(rms(mlst_spshn_4channel)) db(rms(mlst_ists_4talker))] - db(rms(hint_spshn)), 's')
legend('MLST WAV Files', 'MLST MP4 Files', 'MLST SPSHN', 'location', 'EastOutside')

%% WORD SPAN
%
%   Below we calibrate the word span by loading the carrier phrase and
%   calibrating relative to our calibration sound. CWB talked to Christi
%   Miller on 12/16/14 and she suggested doing the calibration this way,
%   which is simpler and closer to what is typically done for tests of this
%   type in the clinic. CWB was very happy to do less work ;). 

% Load a file with the carrier phrase in it.
%   We'll use a predefined file here so we can hard code the time windows.
[word_span_carrier, word_span_fs] = SIN_loaddata(fullfile(fileparts(which('runSIN')), 'playback', 'Word Span', 'List01', '00.wav')); 

% Sampling rate sanity check
if word_span_fs ~= FS, error('Word span sampling rate does not match'); end

% Bandpass filter the file
[b, a] = butter(bandpass_filter_order, filter_frequency_range./(FS/2), filter_type);
word_span_carrier = filtfilt(b, a, word_span_carrier); 

% Extract the carrier phrase. 
word_span_carrier = word_span_carrier([44316:85994],1); 

% % Write carrier phrase as a temporary file
% audiowrite(fullfile(fileparts(which('runSIN')), 'playback', 'calibration', 'WordSpan_carrier.wav'), word_span_carrier, FS, 'BitsperSample', audio_bit_depth);

% Load calibration file 
hint_spshn = SIN_loaddata(calibration_file); 

% Calculate scaling factor
word_span_scale = rms(hint_spshn)./rms(word_span_carrier); 

% Load word span play lists
opts = SIN_TestSetup('Word Span (70 dB SPL)', ''); 

% Change regular expression for wav file selection
opts.specific.wav_regexp = '[0-9]{2}.wav$';

% Load get file names
[~, word_span_files] = SIN_stiminfo(opts); 

% Concatenate file names
word_span_files = concatenate_lists(word_span_files); 

% Loop through all files, scale, write new files
for i = 1:numel(word_span_files)
    
    % Get the file name and path
    [PATHSTR, NAME, EXT] = fileparts(word_span_files{i}); 
    
    % Load the data and bandpass filter it.
    [word_span_data, fs] = SIN_loaddata(word_span_files{i}); 
    word_span_data = filtfilt(b, a, word_span_data);     
    
    % Apply scaling factor to data
    word_span_data = word_span_data .* word_span_scale; 
    
    % Sampling rate check
    if fs ~= FS, error('Sampling rate mismatch'); end 
    
    outfile = fullfile(PATHSTR, [NAME ';bandpass;0dB' EXT]); 
    
    % Write new file to disk
    %   Write as a single channel file. 
    audiowrite(outfile, word_span_data(:,1), FS, 'BitsperSample', audio_bit_depth);
    
end % for i=1:numel(word_span_files)

% Create the lookup table
create_wordspan_lookup('suffix', ';bandpass;0dB');