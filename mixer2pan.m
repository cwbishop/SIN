function pstr = mixer2pan(mixer, varargin)
%% DESCRIPTION:
%
%   Function to convert a DxP mixer to a pan string used by the pan
%   parameter in FFmpeg.
%
% INPUT:
%
%   mixer:  DxP mixer, where D is the number of data channels in the
%           existing file (e.g., 2 channels in a stereo MP4) and P is the
%           number of desired output channels (i.e., the number of channels
%           in the to-be-written file)
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   pstr:   pan string argument suitable for use with FFmpeg
%
% Christopher W. Bishop
%   University of Washington
%   9/14


% cmd = ['ffmpeg -i "' files{i}{k} '" -filter_complex "pan=' num2str(size(data,2)) 'c:c0=1*c0:c1=0*c0" -c:v copy "' ofile '"'];                
pstr=[];

% Quick check to make sure there's something for us to do
if isempty(mixer)
    return
end % if isempty(mixer)

% Base string to build upon
pstr = ['"pan=' num2str(size(mixer,2)) ':'];

% Loop through each output channel and each data channel to construct the
% pan string
for p=1:size(mixer,2)
    
    for d=1:size(mixer,1)
        
        % For first entry, we need the assignment operator
        if d == 1
            pstr = [pstr 'c' num2str(p-1) '='];            
        else
            pstr = [pstr '+'];
        end 
        
        pstr = [pstr num2str(mixer(d,p)) '*c' num2str(d-1)];        
        
    end % for d=1:size(mixer,1)
    
    % Add colon to separate output channels
    if p ~= size(mixer,2)
        pstr = [pstr ':'];
    end 
end % for p=1:size(mixer,2)

% Add the last quote
pstr = [pstr '"'];

