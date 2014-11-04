function [channel_number, channel_map] = map_channels(device, field_name, varargin)
%% DESCRIPTION:
%
%   This function creates a channel mapping matrix used by PsychPortAudio
%   to do appropriate sound mappings.
%
%   Use iterative calls for playback/recording sound setup since these are
%   currently handled in different mat files. 
%
% INPUT:
%
%   device: device structure returned from portaudio_GetDevice (a SIN
%           function written by CWB)
%
%   field_name: device field used we are configuring (e.g.,
%               'NrOutputChannels')
%
% Parameters:
%
%   'title':    see SIN_select
%
%   'prompt':   see SIN_select
%   
%   'max_selections':   see SIN_select
%
% OUTPUT:
%
%   channel_number: the number of channels used by the device.
%
%   channel_map: 1 x channel_number matrix with channel mapping.
%
% Development:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   11/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

% Ask how many channels the user wants to use
[~, channel_number] = SIN_select(cell(device.(field_name),1), 'title', d.title, 'prompt', 'How many channels?', 'max_selections', 1);

% Now map a physical channels to data channels. 
for i=1:channel_number
    [~, channel_map(1, i)] = SIN_select(cell(device.(field_name),1), 'title', d.title, 'prompt', ['Map Channel ' num2str(i) ' to : '], 'max_selections', 1);
end % for i=1:channel_number

% Review the setup 
[~, review_selection] = SIN_select({struct('channel_number', channel_number, 'channel_map', channel_map) 'Reconfigure'}, 'title', 'Review', 'prompt', 'Review the Setup', 'max_selections', 0);

% If the user wants to reconfigure, then make a recursive call to
% map_channels. 
if review_selection == 2
    map_channels(device, field_name, d);
end % if review_selection == 2

% Modify channel map to work with 0 indexing
%   Recall that channels begin with index 0 in PsychToolBox. 
%   See http://docs.psychtoolbox.org/Open for more information.
channel_map = channel_map - 1; 