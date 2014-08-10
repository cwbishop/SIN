function mixer = fillPlaybackMixer(device, mixer, val)
%% DESCRIPTION:
%
%   Function to create a mixer of appropriate size for the playback device. 
%   This proved useful when using SIN on machines with
%   different devices (e.g., 8-channel playback using the Halo Claro and 
%   two-channel sound playback using standard two channel cards).
%
% INPUT:
%
%   device: device information, as required by portaudio_GetDevice. See
%           help portaudio_GetDevice for more information.
%
%   mixer:  double array, values corresponding to values to be applied to
%           each channels of the playback device. D x P array, where D is
%           the number of data channels and P is the number of playback
%           channels (often referred to physical channels in the
%           documentation). 
%
%   val:    double, value to set missing mixer values to.
%
% OUTPUT:
%
%   mixer:  filled mixer
%
%
% Example uses:
%
%   XXX   
%
% Development:
%
%   XXX
%   
% Christopher W. Bishop
%   University of Washington
%   8/2014

%% GET DEVICE INFORMATION
device = portaudio_GetDevice(device); 

%% FILL MISSING VALUES?
%   Do we need to fill in missing values?
if size(mixer, 2) ~= device.NrOutputChannels % check number of playback (physical) channels
    mixer = [mixer val*ones(size(mixer, 1), device.NrOutputChannels - size(mixer, 2))];     
end % if size(mixer, 2)
