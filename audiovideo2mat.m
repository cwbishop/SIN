function audiovideo2mat(X, varargin)
%% DESCRIPTION:
%
%   Function to convert audiovisual (AV) files - like MP4s - into a mat
%   file. CWB hopes that the MAT files can be read more efficiently than
%   the videos. This should (theoretically) decrease load times during
%   testing.
%
% INPUT:
%
%   X:  cell array, list of videos to be converted
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   8/14

%% LOOP THROUGH FILES
for i=1:numel(X)
    
    display(['Loading file: ' X{i}]); 
    waitbar(i/numel(X));
    
    % Get file parts
    [PATHSTR,NAME,EXT] = fileparts(X{i}); 
    outstr = fullfile(PATHSTR, [NAME '.mat']);
    % Load the video
    %   Returns AV structure.
    av = SIN_loaddata(X{i});
    
    % Save to mat file
    display(['Saving file: ' outstr]); 
    save(outstr, 'av'); 
    
end % for i=1:numel ...