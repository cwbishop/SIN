function recovered_device = SIN_recoverDevice(device, varargin)
%% DESCRIPTION:
%
%   This function attempts to recover a sound playback/recording device in
%   teh event that its DeviceIndex field has changed. This occurs
%   frequently and most notably when sound hardware is added or removed
%   (e.g., a USB device) or (I think) when users change their sound
%   playback/recording settings through Windoze. 
%
% INPUT:
%
%   device: structure returned from portaudio_GetDevice.
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   matched_device: device structure returned from portaudio_GetDevice.
%                   This is the proposed matched device.
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

%% GET AVAILABLE DEVICES
%   Try getting the devices. If that fails, try initializing PsychSound,
%   then get the devices. 
try 
    available_devices = PsychPortAudio('GetDevices');
catch
    InitializePsychSound;
    available_devices = PsychPortAudio('GetDevices');
end % try/catch

%% LOOK FOR MATCH
%   The most typical reason devices need to be recovered is if the device
%   index changes. As described in the help section above, this can happen
%   under several common circumstances. So, here we look for a device that
%   matches in all fields *except* the device index
for i=1:numel(available_devices)
    
    % Run check to see if we have a match or not
    df = comp_struct(rmfield(available_devices(i), 'DeviceIndex'), rmfield(device, 'DeviceIndex'), 0);
    
    % Track if we have a match
    if isempty(df)
        match_mask(i) = true;
    else
        match_mask(i) = false;
    end % 
end % for i=1:nume(available_devices) ...

%% DID WE FIND ONE AND ONLY ONE MATCH?
if numel(match_mask(match_mask)) == 1
    recovered_device = available_devices(match_mask);
else
    error('Could not recover device');
end % if numel(match_mask ...