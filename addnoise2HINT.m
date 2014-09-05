function addnoise2HINT(NFILE, varargin)
%% DESCRIPTION:
%
%   Function to add noise to HINT stimuli. User must provide a wav file
%   with the noise. Assumes HINT stimuli are in the ../playback/HINT
%   directory (hard coded for ease).
%
% INPUT:
%
%   NFILE:    path to wavfile containing noise stimulus.
%
% Parameters:
%
%   'testID':   string, test ID that has the most relevant fields and
%               information (likely 'HINT (SNR-50, Sentence-Based)'); 
%
%   'nmixer':   NoiseChannel x HintChannel mixing matrix. The noise
%               stimulus will be multiplied by the noise mixer (nmixer) to
%               create a stimulus that can be added to each of the sentence
%               stimuli. 
%
%   'suffix':   tag appended to rewritten file
%
%   'leadlag':      two element double array, temporal onset/offset of noise
%                   relative to start/end of HINT stimuli. (units in sec)
%
%   'noiserange':   two-element double array, which time range of the noise
%                   sample to use. The noise sample is often already faded
%                   in/out, so we need to use stable samples somewhere in
%                   the middle. 
%
%   'wav_regexp':   regular expression used to filter WAV files (e.g., 
%                   '[0-9]{2}.wav$').
%
%   'removesilence':    bool, account for silence periods at beginning and
%                       end of sentence files when adding leading/lagging
%                       noise samples. Typically audio files already have
%                       some silence at the beginning and end (in our case
%                       these tend to be zero or very small). We want to
%                       count these samples towards the leading/lagging
%                       times. 
%
%                       If true, then ampthresh must be set as well.
%
%   'ampthresh':    used to remove silence from beginning and end of
%                   acoustic waveforms prior to RMS estimation. 
%
%   'chan4silence': integer, channel to use for silence estimation. This
%                   should typically correspond to the speech track in the
%                   HINT audio files (typically 2). CWB left this as an
%                   input in case the file format changes in later stages
%                   of testing. 
%
%   'bitdepth': integer, bit depth used when writing WAV files. (e.g., 16, 24, 32)   
%
% OUTPUT:
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% PLACE PARAMETERS IN STRUCTURE
d=varargin2struct(varargin{:});  

% Get HINT information
opts = SIN_TestSetup(d.testID, ''); 

%% OVERWRITE FILE FILTER IF NECESSARY
if isfield(d, 'wav_regexp')
    
    input(['Overwriting ' opts.specific.wav_regexp ' with ' d.wav_regexp '. Press enter to continue']);
    
    % Error check to make sure we haven't changed the field name to
    % something else.
    if ~isfield(opts.specific, 'wav_regexp')
        error('wav_regexp field name may have changed');
    end % 
    
    opts.specific.wav_regexp = d.wav_regexp;
    
end % isfield

% Get file names
[~, files] = SIN_stiminfo(opts); 

% Massage into a file list
wavlist={}; 
for i=1:numel(files)
    for k=1:numel(files{i})
        wavlist{end+1, 1} = files{i}{k};  %#ok<AGROW>
    end % for k=1: ...
end % for i=1: ...

% Load noise stimulus
t.dtype=2; % only allow wav
[noise, nfs] = SIN_loaddata(NFILE, t); 

% Find appropriate range for noise stimulus.
%   Recall that the noise sample (at least for HINT) is faded in/out
%   already, so we need to use some samples in the middle. 
d.noiserange = round(d.noiserange .* nfs); 
noise = noise(d.noiserange(1):d.noiserange(2), :); 

% Check noise dimensions
t.fs = nfs; 
noise = SIN_loaddata(noise, t); 

% Loop through each stimulus
for i=1:numel(wavlist)
    
    % Send filename to terminal.
    display(wavlist{i}); 
    
    % Load the wav file
    t.dtype=2; 
    [wav, fs] = SIN_loaddata(wavlist{i}, t);     
    
    % Error check for mismatch in sampling rate
    if fs ~= nfs, error('Sampling rates do not match. Something amiss'); end 
    
    % Account for silence at beginning and end of sentence track?
    if d.removesilence
        
        % Find number of leading samples
        leadtrim = threshclipaudio(wav(:, d.chan4silence), d.ampthresh, 'begin');
        lagtrim = threshclipaudio(wav(:, d.chan4silence), d.ampthresh, 'end');
        
        % How many samples do we think are silence at the beginning of the
        % sound? And the end?
        rmlead = size(wav,1) - size(leadtrim,1); 
        rmlag = size(wav,1) - size(lagtrim,1); 
    else
        % Assume there aren't any silent samples at beginning or end of
        % files otherwise
        rmlead = 0;
        rmlag = 0; 
    end % if d.removesilence
    
    % Calculate number of samples to append to beginning (lead) and end
    % (lag) of wav file
    leadsamps = round(d.leadlag(1)*fs) - rmlead; 
    lagsamps = round(d.leadlag(2)*fs) - rmlag; 
    
    % Create padded data
    wavout = [zeros(leadsamps, size(wav,2)); wav; zeros(lagsamps, size(wav,2))];    
    
    % How many times must the noise be repeated?
    nreps = ceil(size(wavout,1)/size(noise,1));
    
    % Repeat noise nreps times
    %   Use rnoise variable to store "repeated noise". That way, the
    %   original 'noise' samples are not ovewritten or inadvertently
    %   ramped.
    rnoise = repmat(noise, nreps, 1);
    
    % Truncate noise to correct number of samples
    rnoise = rnoise(1:size(wavout,1), :);
    
    % Apply onset/offset ramps to noise
    %   - Use 20 ms ramps
    rnoise = fade(rnoise, fs, true, true, @hann, 0.02); 
    
    % Mix noise with mixer, add to wav file
    wavout = wavout + rnoise*d.nmixer; 
    
    % write 32-bit output wav file
    [pathstr,name,ext] = fileparts(wavlist{i});
    fname = fullfile(pathstr, [name d.suffix ext]);
    audiowrite(fname, wavout, fs, 'BitsperSample', d.bitdepth), 
    
end % for i