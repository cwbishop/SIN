function [allresults]=SIN_calibrate(X, varargin)
%% DESCRIPTION:
%
%   Function to calibrate playback/recording loop. This is still under
%   development.
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
%   'output_root':  root for file output - there will be several results
%                   structures from portaudio_adaptiveplay and an
%                   additional "compiled" data set that will serve as the
% OUTPUT:
%
%   XXX Lots of information XXX
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
%   - We will use this to determine the number of data_channels below.
%   That's pretty much all we'll use it for. 
t.dtype = 2;    % only accept wav files for now.
[stim, fs]=SIN_loaddata(X, t); 
Xdim=size(stim); 

% Resample stimulus
%   Should really wrap this into SIN_loaddata so I know I'm getting the
%   same data across functions. 
stim=resample(stim, d.player.playback.fs, fs); 

%% RECORD RESPONSE FROM REQUESTED PHYSICAL CHANNELS
%   - Get recording
%   - Save results structure to output_root + physical_channel information
%   - Loop through each channel and all that jazz. 
%   - Copy over necessary information 

figtitle = d.player.modcheck.title; 

% maximum length
%   Initialize as length of playback stimulus. 
ml=size(stim,1); 

% Loop through each physical channel in turn
for p=1:length(d.specific.physical_channels)
    
    % Create mod_mixer for portaudio_adaptiveplay
    %   Assume we aren't putting any data into any output channels
    d.player.mod_mixer=zeros(Xdim(2), d.player.playback.device.NrOutputChannels); 
    
    % Play sound from one speaker at full volume
    d.player.mod_mixer(d.specific.data_channels, d.specific.physical_channels(p))=1; 
    
    % Set instructions in ANL_modcheck_keypress
    d.player.modcheck.instructions=d.specific.instructions.playback; 
    
    % Set title
    d.player.modcheck.title = [figtitle 'Channel ' num2str(d.specific.physical_channels(p))]; 
    
    % Run portaudio_adaptiveplay
    results = portaudio_adaptiveplay(X, d); 
    
    % Save results to file
    save(fullfile(PATHSTR, [NAME '-Channel_' num2str(d.specific.physical_channels(p))]), 'results'); 
    
    % Grab data necessary frequency/level matching below.
    
    % save to larger structure
    allresults(p)=results; 
    
    % Copy recorded information to a cell array
    %   Easier to do spectrum matching below.
    rec{p} = results.RunTime.sandbox.mic_recording{1}(:, d.specific.record_channels); 
    
    % Update maximum length if we encounter a longer recording
    if size(rec{p},1) > ml
        ml=size(rec{p},1); 
    end % if size(rec ...
    
    % clear results
    %   Less likely to get in trouble this way. 
    clear results 
    
end % for p=1: ...

%% CREATE FREQUENCY FILTER
%   - Match spectra and levels using SIN_matchspectra.
%   - Probably a good idea to match to average spectrum, then scale filters
%   to match a target output level
%   - Be sure to exclude DC from filtering, but CWB not 100% sure about
%   this. Needs to do some soul searching.

% Copy maximum length over to nfft field.
d.specific.matchspectra.nfft=ml; 

% Filter estimation is a two step process:
%
% Step 1:
% Match all speakers to specified channel
%   With this filter, we equate all speakers to the match2channel speaker. 
%
% Step2: 
% Match match2channel speaker to original sound
%   This step effectively "flattens" the frequency response of the
%   speakers. It does *not* do anything about the relative phase. We don't
%   want to correct phase anyway. 
for p=1:length(d.specific.physical_channels)
    
    % Extract the arguments we need for matchspectra
    %   dPyy is the filter applied to Y (rec{p}) to match X (match2channel)
    %   Units are dB (for dPyy at least). See SIN_matchspectra for other
    %   details. 
    [Pxx, Pyy, Pyyo, Y, Yo, FS, tdPyy]=SIN_matchspectra(...
        rec{d.specific.physical_channels==d.specific.match2channel}, ... % recording from reference speaker
        rec{p}, ... % recording from a speaker
        d.specific.matchspectra, ... % pass necessary inputs to SIN_matchspectra
        'fsx',  d.player.record.fs, ... % sampling rate of X
        'fsy',  d.player.record.fs);  % sampling rate of Y 
    
    % Save filter information
    dPyy(:, p)=tdPyy; % filter in dB
    clear tdPyy;     
    
    % Extract the arguments we need for matchspectra
    %   dPyy is the filter applied to Y (rec{p}) to match X (match2channel)
    %   Units are dB (for dPyy at least). See SIN_matchspectra for other
    %   details. 
    [Pxx, Pyy, Pyyo, Y, Yo, FS, tdPyy]=SIN_matchspectra(...
        stim, ... % original sound
        rec{p}, ... % recording from a speaker
        d.specific.matchspectra, ... % pass necessary inputs to SIN_matchspectra
        'fsx',  d.player.record.fs, ... % sampling rate of X
        'fsy',  d.player.record.fs);  % sampling rate of Y 
    
    % Add filter information
    dPyy(:, p)=dPyy(:, p)+tdPyy; % in dB, so add (not multiply).
    
end % for p=d ...

%% VALIDATE FREQUENCY FILTERS
%   - Repeat the recordings above, but this time with the filtered sound
%   output file. 
%   - Compute spectra and levels as we would normally and compare

%% DIAGNOSTICS
%   - Determine how well our filters are working. 
%   - Perhaps establish some guidelines 
