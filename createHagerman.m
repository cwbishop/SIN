function createHagerman(target, noise, FS, SNRs, varargin)
%% DESCRIPTION:
%
%   Function to create stimuli for Hagerman recordings. The basic idea is
%   to provide a method of estimating SNR, a flag for holding the noise or
%   speech track constant, and a naming scheme to use to save the output
%   files.
%
%   Hagerman stimuli for Project AD: HA SNR are comprised of ~1 minute of
%   concatenated HINT sentences (e.g., List01 - List03) paired with one of
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
%   target: cell array, file or file(s) to concatenate to create the target
%           track.
%
%   noise:  path to file containing noise sample.
%
%   FS:     sampling rate for output data (and files). 
%
%   SNRs:   N-element vector, where each element specifies the desired SNR
%           (in dB). 
%
% Parameters:
%
%   'target_mixer': Dx1 array, where D is the number of channels in the wav
%                   files and 1 is the number of resulting target channels 
%                   (this can be 1 and only 1 as coded).
%
%   'noise_mixer':  like target_mixer but applied to the noise sample.
%
%   'Nnoisechans':  number of noise channels to have in the resulting wav
%                   file
%
%   'holdnoise':    bool, a flag to hold the noise or speech track
%                   constant. If false, then the speech track is held
%                   constant and the noise track is scaled to target the
%                   specified SNR(s).
%
%   'windownoiseby':apply an X sec windowing function to the beginning and
%                   end of noise track. If user does not want any
%                   windowing, set to 0.
%
%   'noiseshift':   the temporal offset applied to noise between sequential
%                   output channels (in sec). 
%
%   'remove_silence':   bool, if set, removes the silence from beginning
%                       and end of noise and target samples before further
%                       processing. If set to TRUE, must also set
%                       signal_threshold parameter. 
%
%   'signal_threshold': double, absolute amplitude threshold to use to
%                       define leading and trailing periods of silence.
%
%   'target_jitter':    two-element array, specifies the temporal jitter
%                       between the end of of the previous target sample
%                       and the subsuquent target. Think of this as
%                       introducing a variable (or fixed) silent period
%                       between target sentences. 
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

%% LOAD AND RESAMPLE STIMULI
%   Load stimuli from file and resample to match user specified sampling
%   rate (FS).

% Load/resample target stimuli
tstim = cell(numel(target), 1);
for i=1:numel(tstim)
    
    % Load stimulus
    [data, fs] = SIN_loaddata(target{i}); 
    
    % Resample stimulus
    data = resample(data, FS, fs); 
    
    % Assign to tstim cell array
    %   Multiply by target mixer. 
    tstim{i} = data*d.target_mixer; 
    
    % Clear variables
    clear data fs 
    
end % for i=1:numel(tstim)

% Load/resample noise stimuli
[data, fs] = SIN_loaddata(noise); 

% Resample noise stimulus
%   Multiply by mixer to reduce to a single channel
nstim = resample(data, FS, fs)*d.noise_mixer; 

%% REMOVE SILENCE 
%
%   If user specifies, remove silence from beginning and ends of target and
%   noise stimuli.
if d.remove_silence
    
    % Remove silence from tstim
    for i=1:numel(tstim)
    
        % Remove silence from beginning and end of stimulus
        tstim{i} = threshclipaudio(tstim{i}, d.signal_threshold, 'begin&end'); 

    end % for i=1:numel(tstim)
    
    % Remove silence from noise
    nstim = threshclipaudio(nstim, d.signal_threshold, 'begin&end'); 
    
end % if d.remove_silence

%% INTRODUCE SILENCE IN TARGET TRACK
%   If specified by the user, introduce a period of silence between each
%   subsequent target stimulus.
%
%   Added silence may be fixed or jittered, depending on user
%   specifications
% if d.target_jitter(1) ~= 0 || d.target_jitter(2) ~= 0
    
% Loop through all stimuli
for i=1:numel(tstim)

    % Figure out the silent gap to apply
    zpad = zeros(round((d.target_jitter(1) + diff(d.target_jitter)*rand(1))*FS), size(nstim,2));

    % Append to stim
    tstim_pad{i} = [tstim{i}; zpad]; 

end % for i=1:numel(tstim)
    
% end % if d.target_jitter 

%% CONCATENATE TARGET FILES
%   Concatenate all target files to generate the "target" stimulus.
% target = [];
targpad = [];
targ = [];
for i=1:numel(tstim)
    
    % Non zero padded target stimulus
    targ = [targ; tstim{i}];
    
    % With zero padding added
    targpad = [targpad; tstim_pad{i}]; 
    
end % for i=1:numel(tstim)

%% MATCH NOISE DURATION TO TARG
%   Need the total number of samples in the noise stimulus to match the
%   target. So, repeat the noise file if we need to. Or truncate it.
if size(nstim,1) > size(targpad,1)
    nstim = nstim(1:size(targpad,1), :); 
elseif size(nstim, 1) < size(targpad,1)
    nstim = [ nstim; nstim(1:size(targpad,1) - size(nstim,1), :)];
end % if size(nstim, 1)

%% CREATE N NOISE CHANNELS
%   Temporally shift the noise in each noise channel
nout = [];
for i=1:d.Nnoisechans
    
    % Shift noise sample by predefined step
    nout(:,i) = circshift(nstim, round(d.noiseshift*(i-1)*FS));
    
end % for i=1:d.Nnoisechans
nstim = nout;

%% WINDOW NOISE
if d.windownoiseby ~= 0
    
    % Fade noise in and out
    nstim = fade(nstim, FS, true, true, @hann, d.windownoiseby);
    
end % d.windownoiseby

%% ESTIMATE POWER OF UNPADDED TARGET
Pxx = db(rms(targ)); 
Pyy = db(rms(nstim)); Pyy = mean(Pyy); % Use the average of all channels - they should be very close anyway

%% SCALE STIMULI
%
%   Need to scale stimuli to generate the required SNR. 
%
%   - If holdnoise is true, then scale the target track. 
%   - Otherwise, scale the noise track. 
nout = nan(size(nstim)); 
for i=1:numel(SNRs)
    
    % Pyy - Pxx gets us to 0 dB SNR.
    nout = nstim .* db2amp(-1*SNRs(i) + (Pxx - Pyy));
    
end % for i=1:numel(SNRs)

%% ADD SIGNAL TAG TO BEGINNING AND END OF TARGET TRACK. 
%   Should we add a tag to the beginning and end of each channel? Would
%   this be way overkill? Probably, but many it will help catch some issues
%   down the road? Dunno. CWB needs to think about it. 