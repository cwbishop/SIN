function [Y, d]=ANL_modifier_dBscale(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Modifier for portaudio_adaptiveplay.m. This particular modifier adjusts
%   the scales the volume levels of a data series on a decibel scale. The
%   modifier is intended to be used to administer the Acceptable Noise
%   Level (ANL) test. 
%
% INPUT:
%
%   X:  double/single precision time series. See AA_loaddata for additional
%       details.
%
%   mod_code:   integer value, modification type to perform.
%
% Parameters:
%   
%   provide a structure, m, with other information in it. What exactly is
%   unclear at time of writing. 
%
% OUTPUT:
%
%   Y:  scaled time series
%
%   m:  structure to be used in successive calls to ANL_modifier_dBscale
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

%% DETERMINE PARAMETERS
%   If an input structure is provided, then we don't need to run
%   SIN_defaults.
%
%   If an input strucutre is not provided, then we need to run SIN_defaults
%   to figure out which way is up. 
try p.modifier.dBstep; % try a random field we know will be there. structs are goofy and tough to work with sometimes (isempty isn't helpful here) 
    d=p; 
    clear p;
catch
    defs=SIN_defaults;
    d=defs.anl;
end % 

%% CHECK DATA DIMENSIONS
%   Might not be the smartest call in the world. d.fs might need to be
%   something different entirely. But still, it's just a placeholder and
%   the sampling rate in this particular instance is totally irrelevant. 
X=AA_loaddata(X, 'fs', d.fs); 

%% APPEND NECESSARY INFORMATION TO d STRUCTURE
%   We need to track information necessary for termination parameters. 
%       Actually, the modcheck might be a better place to do termination
%       stuff. CWB will need to think about this. 

%% SCALE OUTPUT DATA
switch mod_code
        
    case {-1, 0, 1}
        % Scale signal
        %   0 dB is a scaling factor of 1, so no change.        
        Y=X.*db2amp(d.modifier.dBstep.*mod_code); 
        
    otherwise
        error('Unknown mod_code'); 
        
end % switch