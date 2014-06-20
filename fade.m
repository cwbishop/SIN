function [data]=fade(data, fs, fadein, fadeout, winfunc, windur)
%% DESCRIPTION:
%
%   Function to fade sounds in/out by applying a window over a specified
%   time range.
%
%   Uses MATLAB's "window" function to create the fade in/fade out ramps.
%
% INPUT:
%
%   data:   times series to fade. Must be a double/single array. Other data
%           formats can be supported in the future, provided SIN_loaddata
%           can load them easily. 
%
%   fs:     double, sampling rate (Hz) (no default)
%
%   fadein: bool, fade signal in (default = false)
%
%   fadeout:    bool, fade times series out (default = false)
%
%   winfunc: function handle for windowing function (default @hann). See
%           'help window' for more information.
%
%   windur: window duration in sec (no default)
%
% OUTPUT:
%
%   data:   faded times series
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% SET DEFAULTS
if ~exist('fadein', 'var') || isempty(fadein), fadein=false; end
if ~exist('fadeout', 'var') || isempty(fadein), fadeout=false; end
if ~exist('winfunc', 'var') || isempty(winfunc), winfunc=@hann; end

%% LOAD DATA
t.dtype = 1; t.fs=fs; 
[data, ~] = SIN_loaddata(data, t); 

%% CONVERT TIME TO SAMPLES
%   - Need to convert time to samples to create window below
winsamps = round(windur * fs); 

%% GET WINDOW
%   - Make a window 2x the size requested. This will be cut in half below. 
win=window(winfunc, 2*winsamps); % Create onset/offset ramp

% Match number of data_channels
%   data_channels are ramped and mixed to match the number of
%   physical_channels below. 
win=win*ones(1, size(data,2));
            
% Create fade in ramp
ramp_on=win(1:ceil(length(win)/2),:); 
ramp_on=[ramp_on; ones(size(data,1) - size(ramp_on,1), size(ramp_on,2))];

%% APPLY FADE IN
if fadein
    data = data.*ramp_on;
end 

%% APPLY FADE OUT
if fadeout
    data=data.*flipud(ramp_on);
end % 