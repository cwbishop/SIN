function [rec]=Hagerman_record(X, Y, varargin)
%% DESCRIPTION:
%
%   Create Hagerman (phase inverted) recording for two paired signals. Can
%   record an arbitrary combination of X and Y time series (e.g., inverted
%   X, native Y, etc.); 
%
%   The recording procedure is subject to change based on input from
%   Christi Miller and Wu. (pending confirmation as of 5/1/14)
%
%   Additionally, the function can prepend or append a "signal tag" to aid
%   with realignment. For instance, if there is reason to suspect that the
%   playback and recording devices are not engaged at precisely the same
%   moment each time (meaning there's variable time between the start of
%   sound playback and recording), then a "signal tag" can be used to aid
%   with post-hoc realignment. 
%
%   The "signal tag" can be anything the user wants, really. To maintain 
%
%   Function also writes the recordings to file, following a specific
%   naming convention XXX need to figure out how best to handle this while
%   allowing it to remain flexible XXX. XXX Use values set in SIN_defaults.
%   Should be flexible *enough* XXX   
%
% INPUT:
%
%   X:  single or multi channel time series. The number of channels must
%       match the number of elements in 'playback_channels' below. Supports
%       wav format or double/single data matrices. (see AA_loaddata for
%       more information)
%
%   Y:  " " (same as X)
%
% Paramters:
%
%   'fsx':  double, sampling rate for X time series. Only necessary if X
%           is a double/single data series. 
%
%   'fsy':  double, sampling rate of Y time series. Only necessary if Y is
%           a double/single time data series
%
%   'mixing_matrix':    Mx2 double array, with mixing information. For each
%                       row, X is multiplied (scaled) by the first value
%                       and Y is multiplied by the second value. 
%
%                       As an example, if the user wants to record in such
%                       a way to recover the signal in Y from
%                       Hagerman_getsignal, then set mixing matrix to ...
%                           [[0.5 0.5] % Native polarity for both X and Y
%                           [-0.5 0.5]]% Invert X, keep Y in native polarity.
%
%                       Note: 0.5 is used above to prevent clipping during
%                       mixing. Will need to find a smarter way to deal
%                       with this eventually.
%
%                       Alternatively, to get a pure recording of X
%                       followed by a pure recording of Y, use ...
%                           [[1 0]  % just X plays
%                           [0 1]]; % just Y plays
%
%                       Any values can be used, but [-1 1] are most
%                       typical. 
%
%   'write':    bool, flag to write wav data to file. 
%   'write_nbits':  bit depth for written wav files (default = 16 bit). 
%
%   'pflag':    integer, specifies plotting information.
%                   0:  no plots generated (default)
%                   >0: plots generated
%
%   'xtag':     string, tag information for naming purposes. 
%
%   'ytag':     string, tag information for naming purposes. 
%
%   'filename_root':    root filename for wav file output. No default, so
%                       if this is not provided, and 'write' is true, this 
%                       will break. 
%
%   'sigtag_type':  string, type of signal tag. Additional options can
%                   be easily added by expanding a switch statement. 
%                       '10Hzclicktrain':   a train of 10 clicks presented
%                                           at 10 Hz.
%
%   'sigtag_loc':    string, description of when to attach the signal 
%                       tag. ('pre' | 'post' | 'both' | 'none'). No default
%                       is set locally since this will rely heavily on
%                       SIN_defaults. 
%
%   'playback_channels':    integer array, channels to place playback
%                           sounds in. Must be equal to the number of
%                           channels found in X and Y. Each integer
%                           corresponds to a single column of X and Y. For
%                           instance, playback_channels=[2 4] will place
%                           the first column of X and Y in channel 2 and
%                           the second column in channel 4. All other
%                           channels will be "zeroed" out; meaning they'll
%                           play silence. Corresponding columns of X and Y
%                           will be mixed. 
%
% OUTPUT:
%
%   rec:    cell array, each element contains a recording for each row of
%           the mixing_matrix. A cell is used here to support stereo
%           recordings and tolerate potential differences in the number of
%           samples recorded due to any slop in portaudio_playrec. 
%
%   Wav files, if output information specified by the user.
%
% Development:
%
%   1. Find a smarter way to deal with potential clipping problems. 
%   2. Need to make sure that output of signals when mixed matches whatever
%   our calibration procedure is. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

%% INPUT CHECK AND DEFAULTS
%   Load defaults from SIN_defaults, then overwrite these by user specific
%   inputs. 
defs=SIN_defaults; 
d=defs.hagerman; 
FS=d.fs; 

% OVERWRITE DEFAULTS
%   Overwrite defaults if user specifies something different.
flds=fieldnames(p);
for i=1:length(flds)
    d.(flds{i})=p.(flds{i}); 
end % i=1:length(flds)

% Check mixing_matrix field
if size(d.mixing_matrix,2)~=2
    error('Wrong dimensions for mixing matrix.');     
end % if size(d.mixing_matrix) ...

%% CLEAR p
%   CWB wants to pull all information from structure 'd' or 'defs', so get
%   rid of p to remove the temptation to use it. 
clear p;

%% LOAD DATA
%   Load X and Y. Support WAV and double format, multi-channel OK
%   (infinite).
t.datatype=[1 2];
if isfield(d, 'fsx') && ~isempty(d.fsx), t.fs=d.fsx; end 
[X, fsx]=AA_loaddata(X, t); 

if isfield(d, 'fsy') && ~isempty(d.fsy), t.fs=d.fsy; end 
[Y, fsy]=AA_loaddata(Y, t); 

% Playback channel check
%   Confirm that the number of playback channels corresponds to the number
%   of columns of X and Y. 
if numel(d.playback_channels) ~= size(X,2) || numel(d.playback_channels) ~= size(Y,2)
    error('Incorrect number of playback channels specified'); 
end % if numel(p.playback_channels) ...
    
%% MATCH SAMPLING RATE
%   Resample playback sounds so they match the playback sampling rate.
X=resample(X, FS, fsx); 
Y=resample(Y, FS, fsy); 

%% LENGTH CHECK
%   For playback, we need X and Y to be the same size
if size(X,1) ~= size(Y,1)
    error('X and Y time series have different lengths. Fix it, man.');
end % if size(X,1) ~= size(Y,1) 

%% LOAD PLAYBACK AND RECORDING DEVICES
%   Get these from SIN_defaults as well. 
%   Pass to portaudio_GetDevices to get index, then pass this to
%   portaudio_playrec.m.
InitializePsychSound; 

%% CREATE SIGNAL TAG IF SPECIFIED
%   Users can provide a function handle to create a signal tag.
%   Load defaults from SIN_defaults (hagerman section) and modify by user
%   inputs if necessary. 
%
%   Ideas for signal tag include 
%       1. a short click train (implemented)
%       2. a short train of chirps (not implemented)
%       3. short tone pip (not implemented) 
sigtag=[]; 
if ~isempty(d.sigtag_type)
    
    % Figure out which type of signal tag to make
    switch d.sigtag_type
        
        case {'10Hzclicktrain'}
            % Use short clicks (0.125 ms). Arbitrary length. 
            sigtag=create_signaltag(ones(ceil(0.125/1000*FS),1), 1/10, 10, 'fsx', FS); 
            
        otherwise
            error('Unrecognized signal tag type'); 
            
    end % switch
    
end % ~isempty(d.sigtag_type

%% EXPAND SIGTAG
%   Expand signal tag to match the number of playback channels. For now,
%   just play the sigtag out of a single channel (whatever the first
%   playback channel is)
sigtag=[sigtag zeros(size(sigtag,1), size(X,2)-1)];

%% BEGIN PLAYBACK
%   Loop through each mixing combination
for i=1:size(d.mixing_matrix, 1)
    
    % Mix X and Y
    %   Apply mixing_matrix in the process
    out=X.*d.mixing_matrix(i,1) + Y.*d.mixing_matrix(i,2);
    
    % Add signal tag
    if ~isempty(sigtag)
        
        switch d.sigtag_loc
            case {'pre'}
                out=[sigtag; out];
            case {'post'}
                out=[out; sigtag];
            case {'both'}
                out=[sigtag; out; sigtag];
            otherwise
                error('Unknown signal tag location. See help for details');
        end % switch d.sigtag_loc
        
    end % if ~isempty(sigtag)
    
    % Clipping check
    %   Can't play sounds that exceed [-1 1]
    if max(max(abs(out))) > 1
        error('Signal is clipped. CWB has not done anything smart to deal with this issue yet, so we will get this issue a lot'); 
    end % max(max ...
    
    % Create empty playback buffer
    buf=zeros(size(out,1), defs.playback.device.NrOutputChannels);
    
    % Add mixed signal to appropriate channels
    buf(:, d.playback_channels) = out; 
    
    % Playback and record
    trec=portaudio_playrec(defs.record.device, defs.playback.device, buf, FS, 'fsx', FS); 
    rec{i}=trec; 

    %% WRITE DATA TO FILE 
    %   Write recordings to file if specified by the user. 
    if d.write && isfield(d, 'filename_root') && ~isempty(d.filename_root)
        
        % Filename
        fname=[d.filename_root '_' num2str(d.mixing_matrix(i,1)) d.xtag '_' num2str(d.mixing_matrix(i,2)) d.ytag '.wav'];
        
        % Write the file at specified wav depth. 
        wavwrite(rec{i}, FS, d.write_nbits, fname); 
        
    end % if p.write ...
    
end % for i=1:size(d.mixing_matrix, 1)

