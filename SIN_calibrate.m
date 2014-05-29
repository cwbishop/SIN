function SIN_calibrate(X, varargin)
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
[stim, ~]=SIN_loaddata(X, t); 
Xdim=size(stim); 

% Clear stim
clear stim fs; 

%% RECORD RESPONSE FROM REQUESTED PHYSICAL CHANNELS
%   - Get recording
%   - Save results structure to output_root + physical_channel information
%   - Loop through each channel and all that jazz. 
%   - Copy over necessary information 

% Loop through each physical channel in turn
for p=1:length(d.specific.physical_channels)
    
    % Create mod_mixer for portaudio_adaptiveplay
    %   Assume we aren't putting any data into any output channels
    d.player.mod_mixer=zeros(Xdim(2), d.player.playback.device.NrOutputChannels); 
    
    % Play sound from one speaker at full volume
    d.player.mod_mixer(d.specific.data_channels, d.specific.physical_channels(p))=1; 
    
    % Run portaudio_adaptiveplay
    results = portaudio_adaptiveplay(X, d); 
    
    % save to larger structure
    allresults(p)=results; 
    
    % Save results
    save(fullfile(d.specific.output_root, ['Channel_' num2str(d.specific.physical_channels(p))]), 'results'); 
    
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


%% VALIDATE FREQUENCY FILTERS
%   - Repeat the recordings above, but this time with the filtered sound
%   output file. 
%   - Compute spectra and levels as we would normally and compare

%% DIAGNOSTICS
%   - Determine how well our filters are working. 
%   - Perhaps establish some guidelines 
