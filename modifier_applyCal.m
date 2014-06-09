function [Y, d]=modifier_applyCal(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to apply filters estimated during calibration routine
%
% INPUT:
%
%   X:
%
%   mod_code: (ignored here)
%
% OUTPUT:
%
%   Y:  filtered data segment
%
%   d:  unchanged options structure
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% CONVERT INPUT PARAMETERS TO STRUCTURE
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% GET IMPORTANT VARIABLES FROM SANDBOX
trial = d.sandbox.trial; 
modifier_num=d.sandbox.modifier_num; 

%% GET MODIFIER PARAMETERS
% data_channels = d.player.modifier{modifier_num}.data_channels; 
% physical_channels = d.player.modifier{modifier_num}.physical_channels; 

%% INITIALIZE MODIFIER SPECIFIC FIELDS (we'll add to these below)
if ~isfield(d.player.modifier{modifier_num}, 'initialized') || isempty(d.player.modifier{modifier_num}.initialized), d.player.modifier{modifier_num}.initialized=false; end

%% INITIALIZATION
%   For now, there's nothing to do during initialization. But eventually,
%   we'll want to do all kinds of checks to make sure our filters are being
%   correctly applied to the data
%       - Check sampling rate
%       - Check block_duration
%       - Make sure we have sufficient zero-padding for filtering (not
%       straightforward or foolproof, but we need to check it) 
%       -Make sure we have a corrective filter for every playback channel.
%       That's safest.
%       - Should probably estimate and interpolate filter to match the
%       number of points we need (+ zero padding). Interpolate in the
%       frequency domain to prevent spectral splatter associated with
%       zero-padding. But not 100% sure what interpolation method would be
%       "best"
if ~d.player.modifier{modifier_num}.initialized
    
    warning('CWB is doing scaling here for testing purposes'); 
    
    % Assign original data
    Y=X; 
    
    % Set the initialization flag
    d.player.modifier{modifier_num}.initialized=true;
    
    % Load calibration file
    t=load(d.player.modifier{modifier_num}.calfile, 'calibration');
    
    d.calibration=t.calibration; 
    
    return
    
end % if ~d.player.modifier{modifier_num}.initialized

Y = [d.sandbox.prev_data2play_mixed; X; zeros(length(d.calibration.filter.freq_filter) - (size(X,1) + size(d.sandbox.prev_data2play_mixed,1)), size(X,2))]; 

% Get FFT
fftx = fft(Y); 

% Filter (multiply)
Y = real(ifft(fftx .* db2amp(d.calibration.filter.freq_filter))); 

Y = Y(1+size(X,1):size(X,1)*2, :); 

% Y=Y./max(max(abs(Y)));