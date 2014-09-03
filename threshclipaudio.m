function DATA = threshclipaudio(DATA, ampthresh, mode, varargin)
%% DESCRIPTION:
%
%   Function designed to remove silent periods from beginning and end of a
%   sound file. To do this, the code removes all samples preceding the
%   first sample that exceeds the provided (absolute) amplitude threshold.
%
%   The end is clipped such that all samples following the last sample that
%   meets or exceeds the provided amplitude threshold are discarded.
%
% INPUT:
%
%   DATA:   Nx1 data series, where N is the number of samples and 1 is the
%           number of channels. Note that this function is NOT designed to
%           work with multichannel data. 
%
%   ampthresh:  double, absolute amplitude threshold to apply.
%
%   mode:   character, mode of operation.
%
%               'begin':    clip just the beginning
%               'end':      clip just the end
%               'begin&end':    clip beginning and end
% Parameters:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington 
%   9/14

%% INPUT CHECK

% Check data dimensions
DATA = SIN_loaddata(DATA, 'fs', 0); 

% Throw error if incorrect number of channels provided
if size(DATA,2) ~= 1, error('Incorrect number of channels'); end 

%% CLIP BEGINNING
if ~isempty(strfind(mode, 'begin'))
    
    % Find first sample that meets or exceeds threshold
    ind = find(abs(DATA)>=ampthresh, 1, 'first'); 
    
    % Mask the data
    DATA = DATA(ind:end,:);
    
end % if ~isempty(mode, 'begin') 

%% CLIP END
if ~isempty(strfind(mode, 'end'))
    
    % Flip signal, then recursive call
    DATA = threshclipaudio(flipud(DATA), ampthresh, 'begin');
    
    % Now flip it back
    DATA = flipud(DATA); 
    
end % if ~isempty(strfind(mode, 'end')