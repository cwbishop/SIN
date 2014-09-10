function createHagerman(varargin)
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
% Parameters:
%
%   File input and preprocessing:
%
%   'targettracks':  cell array, each element contains the path to a file
%                   that will ultimately be part of the target signal
%                   (e.g., speech track).
%
%   'noisetrack':   string, path to the noise track. 
%
%   'tmixerin':     Dx1 array, where D is the number of channels in the wav
%                   files and 1 is the number of resulting target channels 
%                   (this can be 1 and only 1 as coded).
%
%   'nmixerin':     like target_mixer but applied to the noise sample.
%
%   'removesilence':    bool, if set, removes the silence from beginning
%                       and end of noise and target samples before further
%                       processing. If set to TRUE, must also set
%                       ampthresh parameter. 
%
%   'ampthresh':    double, absolute amplitude threshold to use to
%                   define leading and trailing periods of silence.
%
%   'fsout':    sampling rate of output file in Hz (e.g., 44100)
%
%   SNR Calculation:
%
%   'snrs':         double array, desired SNRs. 
%
%   Noise windowing/timing shifts
%
%   'windownoiseby':apply an X sec windowing function to the beginning and
%                   end of noise track. If user does not want any
%                   windowing, set to 0. Uses a Hanning windowing function
%
%   'noiseshift':   the temporal offset applied to noise between sequential
%                   output channels (in sec). 
%
%   File Output:
%
%   'basename': string, full path to base file name. (e.g.,
%               fullpath('playback', 'Hagerman', 'mywav.wav'); 
%

%
%   'bitdepth': bit depth for output file (e.g., 24)
%
%   'gaprange':         two-element array, specifies the temporal jitter
%                       between the end of of the previous target file
%                       and the subsuquent target. Think of this as
%                       introducing a variable (or fixed) silent period
%                       between target sentences. 
%   'tmixerout':    1xP array, where P is the number of output channels of 
%                   thre returned data. Each coefficient weights and adds
%                   the input target track to the output track
%
%   'nmixerout'     1xP array, like tmixerout about, but mixes input noise
%                   track into output tracks. 
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
tstim = cell(numel(d.targettracks), 1);
for i=1:numel(tstim)
    
    % Load stimulus
    [data, fs] = SIN_loaddata(d.targettracks{i}); 
    
    % Resample stimulus
    data = resample(data, d.fsout, fs); 
    
    % Assign to tstim cell array
    %   Multiply by target mixer. 
    tstim{i} = data*d.tmixerin; 
    
    % Clear variables
    clear data fs 
    
end % for i=1:numel(tstim)

%% CREATE CONCATENATED STIMULUS TRACK
%   Concatenate all stimuli prior to RMS estimation. Might remove silenec
%   as well, if user wants to.
concat = [];
for i=1:numel(tstim)
    
    % Remove silence from target track ?
    if d.removesilence
        concat = [concat; threshclipaudio(tstim{i}, d.ampthresh, 'begin&end')]; 
    else
        concat = [concat; tstim{i}];
    end % if d.removesilence
    
end % 

% Only load noise stimulus if user specifies it
if ~isempty(d.noisetrack)
    % Load/resample noise stimuli
    [data, fs] = SIN_loaddata(d.noisetrack); 

    % Resample noise stimulus
    %   Multiply by mixer to reduce to a single channel
    nstim = resample(data, d.fsout, fs)*d.nmixerin; 
else 
    nstim=[];
end % if ~isempty(d.noisetrack ...

% Should we remove silence from noise as well?
if ~isempty(nstim)
    if d.removesilence
        noiseref = threshclipaudio(nstim, d.ampthresh, 'begin&end'); 
    else 
        noiseref = nstim;
    end % 
    
    % Estimate RMS of target and noise track
    rmstarg = rms(concat); 
    rmsnoise = rms(noiseref);

    % If holdtargSPL is set, then scale the noise to target
    scale = db2amp(db(rmstarg) - db(rmsnoise)); 
    nstim = nstim.*scale; % scale the noise stimulus. 
    
end % ~isempty(nstim)

% Clear potentially confusing variables
clear concat noiseref noise

% Generate output target track
tout = []; % target output track
for i=1:numel(tstim)
    
    % Estimate silent periods at beginning and end of sound
    if i>1
        leadsamps = size(tstim{i-1}, 1) - size(threshclipaudio(tstim{i-1}, d.ampthresh, 'begin'),1);
    else 
        leadsamps = 0; 
    end 
    
    % Always calculate lag samps of current stimulus
    lagsamps = size(tstim{i}, 1) - size(threshclipaudio(tstim{i}, d.ampthresh, 'end'),1); 
    
    % Set random number generator state to a constant so we get the same
    % stimulus every time 
    %   Will likely help prevent errors or oversights by CWB down the road
    rng('default'); % resets default state of random number generate
    
    % Get total number of zeroed samples to add    
    zsamps = round((d.gaprange(1) + diff(d.gaprange)*rand(1))*d.fsout) - (leadsamps + lagsamps);
    
    zpad = [tstim{i}; zeros(zsamps, size(tstim{i}, 2))]; 
    
    % Create zero padded track
    %   Zeros are how we account for silent period after sound offset
    tout = [tout; zpad]; 
    
    clear zpad
    
end % for i=1:numel(tstim)

if ~isempty(nstim)
    % Create matching noise sample
    nout = repmat(nstim, ceil(size(tout,1)./size(nstim,1)), 1); % repmat it to match
    nout = nout(1:size(tout,1)); % truncate to match

    % Mix noise and apply time shift
    nout = remixaudio(nout, 'fsx', d.fsout, 'mixer', d.nmixerout, 'toffset', d.noiseshift, 'writetofile', false);  

    % Fade noise in/out
    nout = fade(nout, d.fsout, true, true, @hann, d.windownoiseby); 
    
end % if ~isempty(nstim)

% Mix tout with tmixerout
tout = tout * d.tmixerout; 

% Now, assuming we're at 0 dB SNR, create requested SNR outputs
for i=1:numel(d.snrs)
    
    % Scale noise, mix to create output track
    if ~isempty(nstim)
        out = tout + nout.*db2amp(d.snrs(i));
    else
        out = tout;
    end % out
    
    % output file name
    [PATHSTR,NAME,EXT] = fileparts(d.basename);
    fname = fullfile(PATHSTR, [NAME '(' num2str(d.snrs(i)) ' dB SNR)' EXT]);
    
    % Write file
    audiowrite(fname, out, d.fsout, 'BitsperSample', d.bitdepth); 
    
end % for i=1:d.snrs 