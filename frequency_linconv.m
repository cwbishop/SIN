function [Xo, FS]=frequency_linconv(X, Y, varargin)
%% DESCRIPTION:
%
%   Function to perform linear convolution between two time series.
%   Convolution is done in the frequency domain for speed. This was written
%   to convolve time series with playback stimuli.
%
%   The user may want to filter just the power, phase, or both. This
%   function supports these options. CWB found this particularly useful
%   because fft(ifft(yoursignal)) can introduce rounding errors that
%   introduce or alter amplitude and/or phase angles of a time series. 
%
% INPUT:
%
%   X:  currently only single/double time series are accepted. No wav
%       files. Only a single time series at a time is supported. 
%
%   Y:  Filter impulse response (time series). 
%
% Parameters:
%
%   'fsx':  sampling rate of x
%
%   'fsy':  sampling rate of y
%
%   'filterType':   
%       'power':    only change power
%       'phase':    only change phase (not well tested)
%       'both':     change phase and power (not well tested)
%   
% OUTPUT:
%
%   Xo: filtered time series
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% LOAD data
%   This just massages the data into the correct dimensions
t.dtype=1;  % just time series for now, no wav files. Should be easy to expand later.
t.fs=d.fsx;
t.maxts=1;  % only one time series (and impulse response) supported for now.
[X, fsx]=SIN_loaddata(X, t); 

t.fs=d.fsy;
[Y, fsy]=SIN_loaddata(Y, t); 

% Get max sampling rate
FS=max([fsx fsy]); 

% Resampling X and Y to highest sampling rate
X=resample(X, FS, fsx); 
Y=resample(Y, FS, fsy); 

% Zero pad X and Y time series
%   For linear convolution in the frequency domain, the two time series
%   must be zero-padded to a length of N+L-1, where N is the length of X,
%   and L is the length of Y. If this is not done, then the operation is
%   "circular convolution" which is an entirely different (and scary)
%   animal. 
%
%   For further discussion on this topic, see
%       http://www.mathworks.com/help/signal/ug/linear-and-circular-convolution.html
lengthx=size(X,1); 
lengthy=size(Y,1); 
ml=lengthx + lengthy; % removed the -1 since it won't hurt to have one extra tap

% Zero padding is leading to spectral leakage and totally destroying the
% shape of my filter
%   http://math.stackexchange.com/questions/26432/discrete-fourier-transform-effects-of-zero-padding-compared-to-time-domain-inte

% Likely need to apply window
% X=[X; zeros(ml-size(X,1), size(X,2))]; 
% Y=[Y; zeros(ml-size(Y,1), size(Y,2))];

%% COMPUTE FFT
%   Use FFT to get frequency domain information
fftx=fft(X); 
ffty=fft(Y); 

% Get amplitude information
ampx=abs(fftx); 
ampy=abs(ffty); 

% Get phase information (angle)
anglex=angle(fftx); 
angley=angle(ffty); 

switch d.filterType
    
    case 'power'
        
        % Multiply together. 
        ampx=ampx.*ampy; 
        
    case 'phase'
        
        % Add angles
        anglex=anglex+angley; 
        
    case 'both'
        
        % Multiply together. 
        ampx=ampx.*ampy; 
        
        % Add angles
        anglex=anglex+angley; 
        
    otherwise
        error(['Unknown filter type: ' d.filterType '. Available options are ' getCases]); 
end % switch

%% RECONSTRUCT (FILTERED) X SERIES
%   Take real part in case of rounding errors or non-Hermitian symmetry. 
Xo=real(ifft(ampx.*cos(anglex) + ampx.*sin(anglex).*1i));

% Truncate to original signal length
Xo=Xo(1:lengthx, :); 