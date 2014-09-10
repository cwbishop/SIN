function [remix]=remixaudio(X, varargin)
%% DESCRIPTION:
%
%   This function is designed to remix audio (e.g., create arbitrary linear
%   combinations of channels in an existing file). Also supports other
%   features during remixing, including introducing arbitrary temporal
%   shifts in the data (using circshift). The latter was especially useful
%   when converting 1 noise channel into multiple, uncorrelated channels
%   for Hagerman recordings. 
%
% INPUT:
% 
%   X:      any (audio) datatype supported by SIN_loaddata.
%
% Parameters:
%
%   For File Loading:
%
%   fsx:    sampling rate of input X if X is not a file name. Used to load
%           the data properly from SIN_loaddata.
%
%   Remixing:
%   
%   mixer:  DxO mixer, where D is the number of data channels in the
%           original file provided by the user, and O is the number of
%           output channels.
%
%   toffset:    DxO matrix of time delays to apply to original data tracks
%               before adding them to the specified output track. Units are
%               in seconds. 
%
%   File Writing:
%
%   writetofile:    bool, flag to write to file. If true, must provide the
%                   following fields: suffix, bitdepth.
%               
%   suffix: string, suffix to append to file name if writetofile flag is
%           set 
%
%   bitdepth:   integer, bit depth for output audio file (e.g., 16, 24,
%               32). Only used if writetofile == true
%
% OUTPUT:
%
%   remix:  NxO matrix, where N is the number of samples and O is the
%           number of output files.
%
%   wav files are written to disk, if specified by user
%
% Christopher W. Bishop
%   University of Washington
%   9/14

%% LOAD PARAMETERS INTO STRUCTURE
d=varargin2struct(varargin{:});

%% INPUT CHECK
if ~isfield(d, 'toffset') || isempty(d.toffset), d.toffset = zeros(size(d.mixer)); end % don't time shift by default

%% LOAD DATA
if isfield(d, 'fsx')
    t.fs = d.fsx; 
else
    t=struct();
end % if isfield(d, 'fsx')

[odata, ofs] = SIN_loaddata(X, t); % original data

%% CONVERT toffset TO SAMPLES
d.toffset = round(d.toffset .* ofs);

%% REMIX AND APPLY TIME SHIFT
%   Remixing requires looping here on account of the potential for time
%   delay inputs from user. Otherwise, we'd just do matrix multiplication
%   here. 
remix = zeros(size(odata,1), size(d.mixer,2)); % initialize with nan (for speed)
for i=1:size(d.mixer,1)
    
    % Load the data channel
    indata = odata(:,i); 
    
    for k=1:size(d.mixer, 2)
        
        remix(:,k) = remix(:,k) + circshift(indata, d.toffset(i,k)).*d.mixer(i,k);
        
    end % for k=1: ...
end % for i=1:size(d.mixer, 1)

%% WRITE OUTPUT
%   Only write if user asks us to. Writing requires the input to be a file
%   name
if d.writetofile
    
    % Get file name information
    [PATHSTR,NAME,EXT] = fileparts(X); % assumes we were provided with a file name to begin with .. hmm..
    
    % Make new file name
    fname = fullfile(PATHSTR, [NAME d.suffix, EXT]); 
    
    % Write file
    audiowrite(fname, remix, ofs, 'BitsperSample', d.bitdepth); 
    
end % if d.writetofile
