function X=create_signaltag(X, soa, nreps, varargin)
%% DESCRIPTION:
%
%   Function to create a repetitive train of a given signal with a
%   specified SOA. 
%
% INPUT:
%   
%   X:  timeseries to use in repetition. Supports double/single and WAV
%       files. 
%
%   soa:    stimulus onset asynchrony (SOA) in seconds. 
%
%   nreps:  integer, number of repetitions. 
%
% Parameters:
%   
%   'fsx':  double, sampling rate of X. Only required if X is a
%           double/single time series. Not required for wav file.
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

%% INPUT CHECKS
%   Don't set any defaults. User needs to tell us what to do, specifically.

%   Only allow a single channel of data, and only support double/single
%   matrix or wav file (types 1 and 2; see AA_loaddata for details). 
t.maxts=1; t.datatype=[1 2];
if isfield(p, 'fsx') && ~isempty(p.fsx), t.fs=p.fsx; end 
[X, FS]=AA_loaddata(X, t); 

%% PAD TO SOA
%   Zero pad to requested SOA
X=[X; zeros(ceil(soa*FS - size(X,1)),1)]; 

%% REPEAT SIGNAL
X=X*ones(1, nreps);

%% RESHAPE
%   Single column output
X=reshape(X, numel(X), 1); 

%% DOUBLE CHECK DATA DIMENSION
X=AA_loaddata(X, t); 