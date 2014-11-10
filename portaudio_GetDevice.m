function [D, map]=portaudio_GetDevice(X, varargin)
%% DESCRIPTION:
%
%   Function to find and return device based on input information. Input
%   information can 
%
%           http://docs.psychtoolbox.org/GetDevices
%
%   Function also provides a basic device check to make sure the device
%   information is not out of date. 
%
% INPUT:
%
%   X:  Various information can be provided to gather the device
%       information. Ultimately, the device structure is returned. 
%
%       string, name of device (see 'DeviceName' field from return from 
%       PsychPortAudio('GetDevices')). 
%
%       integer, device ID returned from PsychPortAudio('GetDevices'); 
%
% Parameters:
%   
% These parameters are only used in the event a file path is provided to a
% MAT file that (presumably) contains the device information in a variable
% called 'device' and that file does *not* exist *or* the appropriate
% variable (device) is not found in the MAT file. Otherwise, these fields
% are unnecessary. These are typically only called during initial setup of
% SIN on a new machine or if the device configuration has changed. 
%
% Note: If mat_file is specified and the device must be "recovered" (e.g.,
% if the device index has changed), then the device will be saved to the
% provided mat file. 
%
%   For a more detailed and likely more up-to-date description of these
%   parameters, see SIN_select.m. 
%
%   'title':    string, title for SIN_select if it's called. 
%
%   'prompt':   string, prompt for SIN_select if it's called.
%
%   'mat_file': string, path to mat-file to save device in (e.g., a default
%               file)
%
%   'max_selections':   double, the maximum number of selections that the
%                       user can make. (e.g., 1)
%
%   'field_name':   field name used to select input/outputs. This is
%                   equivalent to the 'field_name' field in map_channels.
%
% OUTPUT:
%
%   D:  structure, device structure. This contains additional subfields
%       based on the device mapping. These subfields include ...
%
%   map:    structure describing the channel map, with the
%           following subfields.
%
%       'channel_number':   the number of channels used by this device
%       'channel_map':  the channel_map established by calls to
%                       map_channels.
%
% Christopher W. Bishop
%   University of Washington
%   4/14

%% DEAL WITH ADDITIONAL PARAMETERS
opts = varargin2struct(varargin{:});

%% DEFAULT PARAMTERS
if ~isfield(opts, 'devicetype'), opts.devicetype=[]; end;

%% INITIALIZE PSYCHSOUND
%   Only initialize psych sound if we can't get the devices. 
try
    % Get devices
    available_devices = PsychPortAudio('GetDevices', opts.devicetype);
catch
    InitializePsychSound;
    available_devices = PsychPortAudio('GetDevices', opts.devicetype);
end % try/catch

% If an index is provided, then just spit back the device structure and
% device index. 
%   Note that the order of the if statements below is very important. Don't
%   switch things up unless you know what you're doing. 
if isempty(X)
    % Return an empty struct if X is not specified
    %   We don't want to return any devices if the user isn't specific. 
    D=struct();
    return

elseif isa(X, 'char')
    
    % Assumes we are trying to load a MAT-file with saved device
    % information in it. 
    
    % First, see if the file exists. If it does not, then let's assume we
    % are setting this up for the first time and need to manually select a
    % device.
    if ~exist(X, 'file')
        
        % Print information to console
        display([X ' does not exist. Running initial setup.']);
        
        % Select the device
        device = SIN_select(available_devices, opts);
        
        % Run check on selection
        device = portaudio_GetDevice(device, opts);
        
        % Map channels
        %   This calls map_channels, which will map the each data stream to
        %   the specified output channel.
        [channel_number, channel_map] = map_channels(device, opts.field_name, 'title', opts.title);
        
        % Copy over to map structure
        map.channel_number = channel_number; 
        map.channel_map = channel_map;
        
        % Save the device to file
        %   Also save mapping information about the device. 
        save(X, 'device', 'map');        
        
        clear device; 
        
    end % if ~exist(X, 'file'); 
    
    % Now load what we just wrote (or was previously written) to file. 
    device_data = load(X); 
    
    % Device stored in device field
    D = device_data.device; 
    map = device_data.map; 
    
    % Run check on device
    D = portaudio_GetDevice(D, opts); 
    
    % Save the loaded information b ack to file.
    %   This is a necessary step when we recover a device (i.e., call
    %   SIN_recoverDevice) since it will save the device without the map
    %   information.
    device = D; 
    save(X, 'device', 'map'); 
    
    clear device
    
elseif isa(X, 'numeric') 
    D=PsychPortAudio('GetDevices', [], X); 
    return
    
elseif isstruct(X)
    
    % Grab the device structure
    td=portaudio_GetDevice(X.DeviceIndex, opts); 
    
    % Compare with what was provided
    %   Suppress the feedback and plotting 
    df=comp_struct(td, X, 0); 

    % If the device has changed in some way, then throw an error
    if ~isempty(df)
        
        warning('Device has changed! Attempting to recover!');
        
        % Attempt recovery
        X = SIN_recoverDevice(X);
        
        % Rerun check to make sure nothing wonky(ier) is happening
        X = portaudio_GetDevice(X, opts); 
        
        % Write recovered file to disk
        if isfield(opts, 'mat_file')
            device = X; 
            save(opts.mat_file, 'device');
            clear device;
        end % if isfield
        
    end % if ~isempty(df) 
    
    % Return the structure. 
    D=X;
    return
    
end % if isempty(X) ...

% % If X is not a string, kick it back
% if ~isa(X, 'char') 
%     error(['I cannot deal with a ' class(X)] ); 
% end % if ~isa(X, 'char'); 
% 
% %% FIND DEVICE
% % Gather names
% dnames={d(:).DeviceName};
% 
% % String match
% Y=strmatch(X, dnames, 'exact'); 
% D=d(Y);
% 
% %% ERROR CHECKING
% %   Throw an error if we find multiple hits
% if numel(Y) > 1
%     error('Multiple devices found. Try specifying the devicetype parameter.');
% elseif numel(Y)==0
%     error('Device not found');
% end % numel(Y)
% 
% %% GET DEVICE ID
% Y=d(Y).DeviceIndex;