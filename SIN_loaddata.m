function [X, FS, LABELS, ODAT, DTYPE]=SIN_loaddata(X, varargin)
%% DESCRIPTION:
%
%   Generalized function to load data from common file types used in
%   project AA (and probably others) as well as generate standardized data
%   format for data matrices, provided some sensible assumptions are met.
%
%   CWB wanted a function that would accept virtually any commonly used
%   input data type (file names, data structures, etc.) of known format and
%   massage the data into a common format that can be used by other
%   functions for analysis and plotting. 
%
% INPUT:
%
%   Required:
%       X:  X can be any of the following
%           - a cell array of file names to ERP/EEG structures, CNT files,
%           WAV files.
%           - ERP/EEG/CNT data structures.
%           - a double (or single) precision, two dimensional matrix. 
%           - an array of vertically concatenated file names. 
%
%   Each of these data types may require additional inputs. Here is a list
%   of additional input parameters followed by a list of dependencies
%   sorted by input file type.
%
%   In addition to the parameter/parameter value pairing listed below, the
%   user can pass a structure with the parameter fields into the function
%   for identical outcomes. 
%
%   Additional fields (General):
%   
%       'fs':   double, sampling rate of data. If required, function 
%               assumes that all data traces (time series, typically) have
%               a uniform sampling rate.
%       'datatype': integer array describing the accepted data types to
%                   load. Typically, functions invoking SIN_loaddata will
%                   only support analysis/plotting with specific data
%                   types. If this is the case, include the integer
%                   identifier of the data types that the invoking function
%                   supports. SIN_loaddata will throw an error if the data
%                   type loaded is not supported. 
%       'chans':    integer array of channels to load. XXX Future
%                   development may include an option to include channel
%                   names rather than integer values. XXX
%       'maxts':    integer value, the maximum number of time series that
%                   should be loaded. This was useful in AA_spectrogram
%                   when ensuring that only one time series is loaded as a
%                   reference time series. (default=Inf). 
%
%   Additional Fields (CNT):
%
%       'lddur':    double, load duration (in seconds). See EEGLAB's
%                   loadcnt.m for more information. (default = all time)
%       't1':       double, start of data to be loaded (sec). (default=0)
%       'chans':    see general section.
%
%   Additional Fields (double):
%
%       'fs':   see general section.
%       
%   Additional Fields (ERP):
%
%       'bins': integer array, which bins to load from an ERP structure.
%               (default=all bins)
%       'chans':    see general section
%
%   Sometimes Required Inputs:
%       
%
% OUTPUT:
%   
%   X:  X is a matrix of data returned based on the inputs. This can either
%       be a TxNxS matrix or CxTxNxS matrix, where C is the number of channels,
%       T is the number of time points, and N is the number of data traces
%       (e.g., bins in an ERP structure) from a single file, and S is the 
%       number of files passed in (usually 1 per subject). 
%           Note: Figuring out the labels for multichannel WAV files might
%                 take some doing.
%
%   FS: The sampling rate of the data.
%   
%   ODAT:   This is a less digested form of the data that might be useful
%           to the user. This differs based on the type of data loaded 
%               double: empty
%               wav:    empty
%               ERP:    an array of ERP structures is returned.
%               EEG:    an array of EEG structures is returned.
%               CNT:    an array of CNT strucutres is returned.
%
%   DTYPE:  integer value specifying a CNT data type
%               1:  double array, single array, logical array
%               2:  wav file, MP3, MP4 files
%                   - note: only audio track of MP4s loaded. 
%               3:  ERP
%               4:  EEG
%               5:  CNT
%               6:  mat files
%
%   LABELS: A cell array of labels for each time series corresponding the
%           the N dimensions of X. Labels vary based on what type of data
%           are loaded.
%               double array:   generic labels (e.g., 'Time Series 1')
%               wav file:       " "
%               ERP:            bin labels from ERP.bindescr field
%               EEG:            XXX undeveloped. Should be channel labels XXX
%               CNT:            channel labels
%   
% Christopher W. Bishop
%   University of Washington
%   3/14

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

%% INITIALIZE VARIABLES

% Check for initialized sampling rate
try FS=p.fs; catch FS=[]; p.fs=[]; end 

% Accept all data types by default
%   Will need to change default as support for new data types are added and
%   supported. 
if ~isfield(p, 'datatype') || isempty(p.datatype)
    
    p.datatype=1:6;
    
end % ~isfield

% LABELS as empty cell (for now). Populated below.
LABELS={}; 

% DTYPE
%   Data type loaded. 
DTYPE=[];
ODAT=[]; % original data. Not always assigned below.

%% DETERMINE DATA TYPE AND WHAT TO DO
if isempty(X)
    % Sometimes users pass in nothing (silly), but we can handle that just
    % fine. 
    display('No data to load'); 
    FS=NaN; 
    
elseif isa(X, 'double') || isa(X, 'single') || isa(X, 'logical')
    % If it's a double, just make sure it's the proper dimensions
    %   Do same data massaging for single precision (common in EEGLAB). 
    DTYPE=1;
    
    % Input check
    %   If maximum number of time series is not defined, then assume it's
    %   infinite. 
    if ~isfield(p, 'maxts'), p.maxts=Inf; end 
    
    % If the number of time series exceeds p.maxts, throw an error. Useful
    % when ensuring that a loaded wav file is not (or is) stereo. Typically
    % we want a single time series for the "X" input to the parent
    % function. 
    if min(size(X))>p.maxts
        error('Exceeds maximum number of dimensions'); 
    end % if min(size(X))>1
    
    % Dimension checks
    %   Assume that the shortest dimension are the individual time series. 
    if numel(size(X))>2
        error('Too many dimensions');
    elseif size(X,1) == size(X,2)
        error('This is a square matrix, not sure what to do with it');
    elseif size(X,1)==min(size(X))
        X=X';
    end % if ... 
    
    % Create default labels for plotting
    for n=1:size(X,2)
        LABELS{n}=['TimeSeries (' num2str(n) ')'];
    end % for n=1:size(X,2)   
    
elseif isa(X, 'char')
    
    % Don't set DTYPE here since there's nothing special or telling about a
    % character array. 
    
    % Convert to a cell if it's a character matrix
    X={X};
    
    % Sommersault
    [X, FS, LABELS, ODAT, DTYPE]=SIN_loaddata(X,p); 
elseif isa(X, 'cell') 
    % Filenames will be necessarily stored in a cell array.
    
    % Try reading in as a wav file. If that fails, assume it's an ERP file.
    % If THAT fails, then we're clueless.
    x=[];
    for n=1:length(X)
        [pathstr,name,ext]= fileparts(X{n});
        
        % Determine file type to load. 
        switch lower(ext)
            case {'.wav' '.mp3' 'mp4'}
                % If this is a WAV file
                DTYPE=2;
                [tx, FS]=audioread(X{n}); 
                x=[x tx]; % multichannel support                
               
            case {'.erp', '.set'}
                % If the data are either an ERP structure (stored as a .mat
                % or .erp file extension) or an EEG struture (stored as a
                % .mat or .set file)
                
                % First, try loading the ERP, then try loading the EEG data
                % set.
                try 
                    DTYPE=3;
                    x(n)=pop_loaderp('filename', [name ext], 'filepath', pathstr); 
                catch
                    DTYPE=4;
                    x(n)=pop_loadset('filename', [name ext], 'filepath', pathstr); 
                end % try/catch
            case {'.cnt'}
                
                DTYPE=5;
                
                % Defaults
                %   Need to allow loadcnt to set defaults if user doesn't
                %   specify any. So set empty variables (if not defined
                %   already) and let loadcnt do with it as it wills. 
                %
                %   Alternatively, user can specify the load duration
                %   (lddur) and start time (t1). 
                try p.lddur; catch p.lddur=[]; end 
                try p.t1; catch p.t1=0; end 
                
                % If it's a CNT file
                x(n)=loadcnt(X{n}, 'lddur', p.lddur, 't1', p.t1);
                FS=x(n).header.rate;                
                
            case {'.mat'}    
                
                % Load (and return) a mat file
                DTYPE = 6; 
                
                % Load the mat file
                tx = load(X{n}); 
                
                % Gets around an assignment issue since x is intialized as
                % a double matrix.
                if n==1
                    x = tx.results; 
                else
                    x(n) = tx.results;
                end % 
                
                % Assign dummy sampling rate so SIN_loaddata doesn't  buck
                FS = -1; 
            otherwise
                error('File extension not recognized');         
        end % switch 
    end % for n=1:length(X)
    
    % Reassign to X.
    X=x;
    ODAT=X; % save original data structures
    
    % Sommersault to check data size and dimensions. Also load label
    % information. Only do this if it's a time series. At present, data
    % here will either be a time series or a structure. So a simple check
    % is possible. If SIN_loaddata continues to grow, this may no longer
    % work.     
    if ~isstruct(X)
        % If we know the sampling rate, then pass hold it constant in
        % sommersault. 
        if ~isempty(FS), p.fs=FS; end 
        dtype=p.datatype;
        p.datatype=[];   

        [X, FS, LABELS]=SIN_loaddata(X, p); 
        p.datatype=dtype;

        clear dtype; 
    end % if isstruct 
    
elseif iscntstruct(X)
    DTYPE=5; 
    % If we're dealing with a CNT structure
    
    % Defaults
    
    % Load all channels by default
    try p.chans; catch p.chans=1:numel(X(1).electloc); end 
    
    % Set sampling rate
    %   Assume all sampling rates are equal
    FS=X(1).header.rate;
    
    % Return channel labels as LABELS
    %   Assumes channel labels are the same across all data files.
    %   Reasonable assumption, but maybe not the safest.
    LABELS={X(1).electloc(p.chans).lab}; 
    
    % Load specified channels
    for n=1:length(X)
        
        % Set default load duration
        try p.lddur; catch p.lddur=size(X(n).data, 2) / FS; end
        
        % Get data traces
        tx=X(n).data(p.chans, 1:round(p.lddur*FS)); 
        % massage into uniform format
        p.maxts=Inf; % infinite data traces OK
        tx=SIN_loaddata(tx, p); 
        % Reassign
        x(:,:,n)=tx;
    end % for n=1:length(X)
    
    % Reassign and return
    X=x; 
    
elseif iserpstruct(X)
    DTYPE=3;
    % Defaults
    
    % Load all channels by default
    try p.chans; catch p.chans=1:size(X(1).bindata, 1); end  
    
    % Load all bins by default
    try p.bins; catch p.bins=1:size(X(1).bindata, 3); end 
    
    % Set sampling rate
    %   Assumes all sampling rates are equal
    %   Also assumes that bin labels are the same across all ERP
    %   structures. Reasonably safe.
    FS=X(1).srate;   
    p.fs=FS; 
    LABELS={X(1).bindescr{p.bins}}; % bin description labels
    for n=1:length(X)
    
        % Truncate data
        for c=1:length(p.chans)
            tx=squeeze(X(n).bindata(p.chans(c), :, p.bins)); 
        
            % Sommersault to reset data dimensions if necessary
            [tx]=SIN_loaddata(tx, p); 
            
            % Assign to growing data structure
            x(c,:,:,n)=tx; 
        end % c=p.chans
        
    end % for n=1:length(X)
    
    % Reassign to return variable X
    X=x; 
    clear x; 
    
elseif iseegstruct(X)
    DTYPE=4;
    warning('EEG structure loading is underdeveloped'); 
    ODAT=X;    
else
    error('Dunno what this is, kid.');
end  % if ...

%% CHECK DATA TYPE
%   Make sure the data type that is being loaded is supported by the
%   function invoking SIN_loaddata
if ~ismember(DTYPE, p.datatype)
    error('Data type not supported by invoking function');
end % if ~ismember(DTYPE, p.datatype)

% Check sampling rate
%   Set sampling rate if it's unknown from SIN_loaddata but specified by the
%   user. 
%
%   If FS is unknown by SIN_loaddata and the user doesn't supply one, then
%   throw an error. We won't be able to make much sense out of this later
%   during plotting routines.
if ~isempty(p.fs) && isempty(FS)
    FS=p.fs;
elseif isempty(p.fs) && isempty(FS)
    error('Sampling rate undefined.'); 
end % if ~isempty(p.fs) && ... 

end % function SIN_loaddata