function output_file_names = createHagerman(varargin)
%% DESCRIPTION:
%
%   Function to create stimuli for Hagerman recordings. The basic idea is
%   to provide a method of estimating SNR, a flag for holding the noise or
%   speech track constant, and a naming scheme to use to save the output
%   files.
%
%   Hagerman stimuli for Project AD: HA SNR are comprised of ~1 minute of
%   concat_target_trackenated HINT sentences (e.g., List01 - List03) paired with one of
%   several noise types (speech-shaped noise (SSN) and ISTS). 
%
%   Other flags provide information regarding the number of noise channels
%   to create and what time delay should be applied to each of the noise
%   channels - recall that SSN and ISTS are single channel files
%
%   Note: noise and target tracks are assumed to be single channel. If they
%   are stereo, the second channel is used. (Confusing, I know, but the
%   HINT stims that CWB have the target in the second channel). 
%
% INPUT:
%
% Parameters:
%
%   File input and preprocessing:
%
%   'target_tracks':  cell array, each element contains the path to a file
%                   that will ultimately be part of the target signal
%                   (e.g., speech track).
%
%   'target_input_mixer':     Dx1 array, where D is the number of channels in the wav
%                   files and 1 is the number of resulting target channels 
%                   (this can be 1 and only 1 as coded). This is the data
%                   loaded from WAV files (or other media sources) are
%                   matrix multiplied with this mixer to create a
%                   single-channel, mixed signal that will be come the
%                   "target track".
%
%                   *Note*: the mixer values for target_input_mixer and noise_input_mixer should
%                   *always* be position. So should the target_output_mixer and
%                   noise_output_mixer. Including negative numbers will lead to
%                   mislabeled file generation. CWB has placed a couple of
%                   safeguards against this, but you're the first line of
%                   defense.
%
%   'noise_track':   string, path to the noise track. 
%
%   'noise_input_mixer':     like target_mixer but applied to the noise sample.
%
%   'reference_track':  string, path to the reference track used to
%                       RMS normalize the noise and target tracks to 0 dB.
%                       In the context of the SNR grant, this will be the
%                       HINT-SPSHN file, which is our standard for
%                       calibration purposes. 
%   
%   'reference_input_mixer':    like target_input_mixer, but applied to
%                               reference track
%
%   'remove_silence':    bool, if set, removes the silence from beginning
%                       and end of noise and target samples before further
%                       processing. If set to TRUE, must also set
%                       amplitude_threshold parameter. 
%
%   'amplitude_threshold':    double, absolute amplitude threshold to use to
%                   define leading and trailing periods of silence.
%
%   SNR Calculation:
%
%   'snrs':         double array, desired SNRs. 
%
%   Noise windowing/timing shifts
%
%   'noise_window_sec':apply an X sec wifndowing function to the beginning and
%                   end of noise track. If user does not want any
%                   windowing, set to 0. Uses a Hanning windowing function
%
%   'noise_time_shift':   the temporal offset applied to noise between sequential
%                   output channels (in sec). 
%
%   File Output:
%
%   'output_base_name': string, full path to base file name. (e.g.,
%               fullpath('playback', 'Hagerman', 'mywav.wav'); 
%

%
%   'bit_depth': bit depth for output file (e.g., 24)
%
%   'gap_range':         two-element array, specifies the temporal jitter
%                       between the end of of the previous target file
%                       and the subsuquent target. Think of this as
%                       introducing a variable (or fixed) silent period
%                       between target sentences. 
%   'target_output_mixer':    1xP array, where P is the number of output channels of 
%                   thre returned data. Each coefficient weights and adds
%                   the input target track to the output track
%
%   'noise_output_mixer'     1xP array, like target_output_mixer about, but mixes input noise
%                   track into output tracks. 
%
% Visualization Parameters:
%
%   Noise Floor Estimation:
%
%   Hagerman recordings can be affected by the noise floor of our
%   playback/recording loop, so it would be wise to estimate the noise
%   floor in some way. To do this, CWB will write an additional WAV file
%   containing just zeros. This file will be presented and a recording
%   gathered, which will allow us to estimate the noise floor of our
%   playback/recording loop. Should be useful.
%
%   'estimate_noise_floor':    bool, if set, write noise floor estimation file. If
%                       set, user must also define 'noise_floor_sec'
%                       parameter below.
%
%   'noise_floor_sec':    double, duration of recording desired for noise
%                       floor estimation in seconds. 
%
% Development:
%
%   1) CWB must recall that he needs to match the long-term spectrum of the
%   noise sample to the actual target stimuli used.
%
% Christopher W. Bishop
%   University of Washington
%   9/14

%% MASSAGE INPUTS
d=varargin2struct(varargin{:}); 

%% CHECK MIXERS
%   Mixers must only have zeros and positive numbers. Negative numbers will
%   throw off the (rather stupid) naming scheme CWB came up with at the
%   end. CWB thinks he'll end up regretting the quick fix ... CWB in the
%   future, if you're reading this and scratching your head, then you knew
%   you were being an idiot when you wrote this. Silly, silly bear.
if any(d.target_input_mixer ~= 1 && d.target_input_mixer ~= 0) || any(d.noise_input_mixer ~= 1 && d.noise_input_mixer ~= 0) || any(d.target_output_mixer ~= 1 & d.target_output_mixer ~= 0) ||any(d.noise_output_mixer ~= 1 & d.noise_output_mixer ~= 0)
    error('Do not use negative values in your mixing matrices. Bad user! Read the help, please.');
end % if any ...

%% LOAD AND RESAMPLE STIMULI
%   Load stimuli from file and resample to match user specified sampling
%   rate (FS).

% concat_target_trackenate stimuli into a single time series. This is later used in RMS
% estimation routines. 
[concat_target_track, target_fs, target_tracks] = concat_audio_files(d.target_tracks, ...
    'remove_silence', true, ...
    'amplitude_threshold', d.amplitude_threshold, ...
    'mixer', d.target_input_mixer); 

% Assume target_fs will be the sampling rate
FS = target_fs; 

% Return variable
output_file_names = {}; 

% Only load noise stimulus if user specifies it
if ~isempty(d.noise_track)
    
    % Load noise track
    [concat_noise_track, noise_fs] = concat_audio_files(d.noise_track, ...
        'remove_silence', true, ...
        'amplitude_threshold', d.amplitude_threshold, ...
        'mixer', d.noise_input_mixer);     
    
    % Sampling rate error check
    if noise_fs ~= FS, error('Sampling rates do not match'); end 
   
end % if ~isempty(d.noise_track) 

% By this point, we should have noise and target stimuli calibrated to 0
% dB. That is, the SNR should also be 0 dB. We'll work on things from here.

% Set random number generator state to a constant so we get the same
% stimulus every time 
%   Will likely help prevent errors or oversights by CWB down the road
rng(0, 'twister'); % resets default state of random number generate

% Generate output target track
target_output_track = []; % target output track
signal_mask = []; % the signal mask will be TRUE everywhere there's a signal and FALSE where we input silence
for i=1:numel(target_tracks)
    
    % Figure out where our signal is and where relative 'silence' is.
    % Silence is defined here as falling below a predefined amplitude
    % threshold. 
    [~, clip_mask] = threshclipaudio(target_tracks{i}, d.amplitude_threshold, 'begin&end');
    
    if i < numel(target_tracks)
        
        % Find the number of "zero" (or at least below threshold) samples at
        % the beginning and end of the sound.
        %
        %   The threshold estimate needs to be scaled by target_scale since we
        %   scaled target_tracks above.

        [~, clip_mask_next] = threshclipaudio(target_tracks{i+1}, d.amplitude_threshold, 'begin&end');

        % Find number of "0" samples at the beginning of the NEXT sound and the
        % trailing zeros in the CURRENT trial. These two together tell us how
        % long the "silence" is between sounds already. We'll need to adjust
        % for this below. 
        lag_zeros = size(target_tracks{i}, 1) - find(clip_mask == false, 1, 'last'); 
        lead_zeros = find(clip_mask_next == false, 1, 'first'); 

        % How many zeros do we need to add to the end of the CURRENT sound?
        zeros_to_add = round((d.gap_range(1) + diff(d.gap_range)*rand(1))*FS);
        zeros_to_add = zeros_to_add - (lag_zeros + lead_zeros); 

        % Add the zeros to the current sound
        target_track_padded = [target_tracks{i}; zeros(zeros_to_add, size(target_tracks{i}, 2))];
    
    else
        
        % For the last trial, we just want want to assign the target track
        % We aren't appending any zeros (jitter here would be pointless). 
        target_track_padded = target_tracks{i};
        zeros_to_add = 0; 
        
    end % if 
    
    % Add to growing output_target_track
    target_output_track = [target_output_track; target_track_padded];
    
    % Grow signal_mask
    %   Need to flip bool value of clip_mask since clip_mask tells us which
    %   samples were REMOVED (i.e., are NOT signals)
    signal_mask = logical([signal_mask; ~clip_mask; false(zeros_to_add, 1)]);
    
end % for i=1:numel(target_tracks)

% Check target_output_track size
%   Much of the code below assumes we have a single channel target_track.
%   Let's make sure that's the case
if size(target_output_track,2) ~= 1
    error('Target output track must be single channel'); 
end % if size(target_output_track) ...

% Match the duration of the noise track and target track
if size(concat_noise_track, 1) < size(target_output_track, 1)
    
    % If the noise track is too short, then replicate it 
    concat_noise_track = repmat(concat_noise_track, ceil(size(target_output_track,1)./size(concat_noise_track, 1)), 1);
    
end % if size ...

% Remix the noise sample, including time shifts
%   Note that we want to do the time shifting (and thus the remixing)
%   BEFORE we crop the noise file. Otherwise, we end up time shifting a
%   truncated noise file and it can sound awful depending on how long the
%   target track is. 
noise_output_mixed = remixaudio(concat_noise_track, ...
    'fsx',  FS, ...
    'mixer',    d.noise_output_mixer, ...
    'toffset',  d.noise_time_shift, ...
    'writetofile',  false); 

% Now trim it to match the duration of the target track
noise_output_mixed = noise_output_mixed(1:size(target_output_track,1), :); 

% Fade noise in/out
%   Windowing could potentially affect RMS estimates significantly,
%   depending on the duration of the windowing function. So, let's window
%   (fade in/out) the noise before normalizing the noise levels. 
noise_output_mixed = fade(noise_output_mixed, FS, true, true, @hann, d.noise_window_sec);

% Match RMS of target to RMS of reference
%   The reference file is used to calibrate both the target and noise
%   tracks to 0 dB. 
[reference_track, reference_fs] = SIN_loaddata(d.reference_track); 

% Apply reference mixer.
reference_track = reference_track * d.reference_input_mixer; 

% Sampling rate check
if reference_fs ~= FS, error('Sampling rates do not match'); end

% Scale noise and target to match the reference signal.
target_rms = rms(target_output_track(signal_mask)); % only include the signal in the target_output_track
reference_rms = rms(reference_track); 
target_scale = reference_rms ./ target_rms;
target_output_track = target_output_track .* target_scale; 

% Calculate RMS of noise and scale to 0 dB SPL (that is, match to reference
% track).
%   Note that the calibration is done slightly differently here since we
%   will likely have noise over more than one channel. In sound field, that
%   means the sounds will add constructively and create a higher than
%   expected SPL. To estimate and correct for this interaction, we sum
%   over channels. 
noise_rms = rms(sum(noise_output_mixed,2));
noise_scale = reference_rms ./ noise_rms;
noise_output_mixed = noise_output_mixed .* noise_scale;

% ===============================
% Interim Summary:
%
%   By this point, we have a multichannel noise track (noise_output_mixed)
%   and a single channel target track (target_output_track) that are RMS 
%   equated to a reference signal. The RMS normalization of 
%   target_output_track *excludes* the subthreshold regions of the signal. 
%   The RMS normalization of noise_output_track includes all data samples.
%
%   Each channel of the noise track (noise_output_mixed) and the
%   target_output_track are calibrated to 0 dB. That is, each individual
%   channel (at least those that have a non-zero signal in them) should be
%   calibrated to match the reference sound. 
%
%   Note: There is an option below to correct for multi-channel playback.
%   That is, an option to set the multichannel noise track to 0 dB by
%   summing over all noise channels. 
% ===============================
    
% Now, assuming we're at 0 dB SNR, create requested SNR outputs
for i=1:numel(d.snrs)
    
    % output file name
    [PATHSTR,NAME,EXT] = fileparts(d.output_base_name);
    
    % Create 4 combinations of polarity 
    %   target*1, noise*1: TorigNorig
    %   target*-1, noise*1: TinvNorig
    %   target*-1, noise*-1:    TinvNinv
    %   target*1, noise*-1: TorigNinv
    polarity = [[1 1]; [1 -1]; [-1 1]; [-1 -1]];
    
    % Scale the noise_output_channel to create the desired SNR
    noise_output_mixed_scaled = noise_output_mixed .* db2amp(d.snrs(i).*-1);
    
    for n=1:size(polarity,1)       
        
        % Mix target output
        %   Assumes we won't be applying a time shift. Don't think we'd
        %   ever need to for these specific stimuli.
        target_output_mixed = target_output_track * d.target_output_mixer;
        
        % Mix the noise and target
        mixed_output_track = target_output_mixed.*polarity(n,1) + noise_output_mixed_scaled.*polarity(n,2);
        
        % Append the signal_mask
        mixed_output_track = [mixed_output_track signal_mask]; %#ok<AGROW>
        
        % Generate target description string
        if sign(polarity(n,1))==1
            tstr = 'Torig';
        elseif sign(polarity(n,1))==-1
            tstr = 'Tinv';
        else
            error('I broke');
        end %if ...
        
        % Generate Noise description string
        if sign(polarity(n,2))==1
            nstr = 'Norig';
        elseif sign(polarity(n,2))==-1
            nstr = 'Ninv';
        else
            error('I broke');
        end %if ...
        
        % Make file name
        %   For file ordering reasons, we need to force SNR labels to be
        %   two digits for positive SNRs. 
        if d.snrs(i) >= 0
            fname = fullfile(PATHSTR, sprintf('%s;%.2ddB SNR;%s%s%s', NAME, d.snrs(i), tstr, nstr, EXT));
        else
            fname = fullfile(PATHSTR, [NAME ';' num2str(d.snrs(i)) 'dB SNR;' tstr nstr EXT]);
        end 
            
        
        % Append file name to return variable 
        output_file_names{end+1, 1} = fname; 
        
        % Write file
        audiowrite(fname, mixed_output_track, FS, 'BitsperSample', d.bit_depth); 
        
        clear out
    end % 
    
end % for i=1:d.snrs 

%% NOISE FLOOR ESTIMATION?
%   Create WAV file with just zeros for noise floor estimation.
if d.estimate_noise_floor
    
    % Number of zero samples
    nsamps = round(d.noise_floor_sec * FS);
    
    % Make zeros in all output tracks
    noise_floor_track = zeros(nsamps, size(mixed_output_track,2));
    
    % Write file
    fname = fullfile(PATHSTR, [NAME '(noise floor)' EXT]);
    
    % Write file
    audiowrite(fname, noise_floor_track, FS, 'BitsperSample', d.bit_depth); 
    
end % end 