function [wbSNR,nbSNR,f,SIIData] = calcBandSNR_v2(data,fs,audiogram)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [wbSNR,nbSNR,f,SIIData] = calcBandSNR(data,fs,audiogram);
% Function calculates the narrowband and wideband SNR for speech, noise,
% and error files. If an audiogram is provided, the SII is also calcualted.
%
% INPUT ARGUMENTS:
% fs - sampling rate (Hz)
% data - 2 column matrix: column 1 - speech, column 2 - noise
% audiogram - vector of dB HL thresholds at frequencies from 160 to 8000 Hz
% (1/3-octave intervals)
%
% OUTPUT ARGUMENTS:
% wbSNR - wideband dB SNR (structure w/2 fields: BarPa - averaging done on SNR
% in Pa, BardB - averaging done on SNR in dB)
% nbSNR - narrowband dB SNR (structure w/2 fields: BarPa - averaging done on
% SNR in Pa, BardB - averaging done on SNR in dB)
% f - frequency vector (Hz)
% SIIData - structure containing SII data(SIIData.SII is the SII,
% SIIData.wBandAud is a vector w/each index corresponding to the weighted
% audibility of a frequency band, specified in the output arguement f.
%
% Author: James D. Lewis
% Date: April 12, 2104
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine whether an audiogram was entered
if nargin < 3
    audio = 0;
else
    audio = 1;
end

%-----------------Fixed Parameters and Control Box-----------------------
% Specific to each site. 
%   RMS over calibration tone.
%       - Calibration tone. 
levelCorr_dB = 31.7258; % dB value - difference between cal value (114 dB SPL) and *.wav value
% Pascals, should not need to change. 
pref = .00002; % reference pressure for dB SPL
newFs = 22050;
%------------------------------------------------------------------------

%-------------Variable Values for SII Calculation-----------------
% Nominal midband frequency (Hz), note that these are approximately the
% center frequencies of the 1/3 octave band filters used in this
% implementation but not the exact frequencies...
freq = [160 200 250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000 5000 6300 8000]; % Table 3 ANSI S3.5-1997
% SII requires the speech and noise spectra to be expressed in the
% free-field. Accordingly, ear drum measurements must be converted to the
% free-field by subtracting the free-field to TM transfer function.
freeField2TM = [0 0.5 1 1.4 1.5 1.8 2.4 3.1 2.6 3 6.1 12 16.8 15 14.3 10.7 6.4 1.8]; % Table 3 ANSI S3.5-1997
% Reference Equivalent Threshold Sound Pressure Levels
RETSPLInsert = [24.5 21.5 17.5 15.5 13 9.5 7.5 5.5 5.5 8.5 9.5 11.5 13.5 13 15 18.5 16 15.5]; % Table 7 ANSI S(1)3.6-2004 Occluded Ear Simulator coupler
RETSPLSupra = [38.5 32.5 27 22 17 13.5 10.5 8.5 7.5 7.5 8 9 10.5 11.5 12 11 21 15.5]; % Table 6 ANSI S(1)3.6-2004 IEC 60318-3 coupler
% Reference Internal Noise Spectrum (dB)
X = [.6 -1.7 -3.9 -6.1 -8.2 -9.7 -10.8 -11.9 -12.5 -13.5 -15.4 -17.7 -21.2 -24.2 -25.9 -23.6 -15.8 -7.1]; % Table 3 ANSI S3.5-1997
% Standard Speech Spectra for Various Vocal Efforts (dB)
%   Just use Normal vocal effort for now. Wu/CWB 140429
UNormal = [32.41 34.48 34.75 33.98 34.59 34.27 32.06 28.3 25.01 23 20.15 17.32 13.18 11.55 9.33 5.31 2.59 1.13]; % Table 3 ANSI S3.5-1997; Normal vocal effort
% URaised = [33.81 33.92 38.98 38.57 39.11 40.15 38.78 36.37 33.86 31.89 28.58 25.32 22.35 20.15 16.78 11.47 7.67 5.07]; % Raised vocal effort
% ULoud = [35.29 37.76 41.55 43.78 43.3 44.85 45.55 44.05 42.16 40.53 37.7 34.39 30.98 28.21 25.41 18.35 13.87 11.39]; % Loud vocal effort
% UShout = [30.77 36.65 42.5 46.51 47.4 49.24 51.21 51.44 51.31 49.63 47.65 44.32 40.8 38.13 34.41 28.24 23.45 20.72]; % Shout vocal effort
% Band Importance
I = [.0083 .0095 .015 .0289 .044 .0578 .0653 .0711 .0818 .0844 .0882 .0898 .0868 .0844 .0771 .0527 .0364 .0185]; % Table 3 ANSI S3.5-1997
%-----------------------------------------------------------------

%-----------------Design and Build 1/n Octave Filters--------------------
% Generate 1/n octave band filters
octaveStep = 1/3;
nBands = 18;
fStart = 160; % Per ANSI S3.5-1997 Table 3
filterF = (log2(fStart):octaveStep:log2(fStart)+(nBands-1)*octaveStep); % Center frequencies for filters
fcLowDesign = filterF - (octaveStep/2); % Frequency corresponding to low-side cutoff frequency
fcHighDesign = filterF + (octaveStep/2); % Freqeuncy corresponding to high-side cutoff frequency
filterF = 2.^(filterF); % convert frequency back to Hz
fcLowDesign = 2.^(fcLowDesign);
fcHighDesign = 2.^(fcHighDesign);
MStart = 4096; % Filter order for lowest center frequency
bwDesign = fcHighDesign - fcLowDesign; % bandwidth of filters
% Calculate the order for all filters such that energy in signal is
% preserved after filtering
for ii = 1:1:nBands
    if ii == 1
        M(ii) = MStart;
    else
        M(ii) = floor(M(ii-1)*(bwDesign(ii-1)/bwDesign(ii)));
    end
    % Ensure filter order is even
    if mod(M(ii),2)
        M(ii) = M(ii) + 1;
    end
end

% Build filters
for kk = 1:1:nBands
    OBFilters.(['band',num2str(kk)]) = buildOBFilters(fcLowDesign(kk),fcHighDesign(kk),M(kk),newFs);
end
%------------------------------------------------------------------------

%% Prep recording for filtering
% Resample to 22.05 kHz
oldFs = fs;
data = resample(data,newFs,oldFs);

% Chop to time from 30 - 60 seconds
%% Prep recording for filtering
N = length(data); % Number of samples in waveform
start = 30; % analysis starts at 30 seconds
startN = floor(start*newFs);
finish = 60; % analysis ends at 60 seconds
finishN = floor(finish*newFs);

% Ramp signal on and off to reduce filter ringing
rampDur = .250; %  ramp duration in seconds
nRamp = ceil(rampDur*newFs); % number of samples in ramp - 1
% Check to ensure length of signal is sufficient for ramps
if (N - finishN - 1) < nRamp + 1
    % If the signal is not long enough for ramps, shift the
    % starting sample and ending sample to allow for the ramps.
    nShort = nRamp - (N - finishN - 1);
    startN = startN - nShort;
    finishN = finishN - nShort;
end
w = hann(nRamp*2 + 1);
w = w(1:nRamp + 1); % Onset and offset ramp
w = repmat(w,1,2);
% Chop down signal to between startN - nRamp:finishN + nRamp
data = data(startN-nRamp:finishN+nRamp,:);
% Ramp onset and offset of speech and noise
data(1:nRamp+1,:) = data(1:nRamp+1,:).*w;
data = flipud(data);
data(1:nRamp+1,:) = data(1:nRamp+1,:).*w;
data = flipud(data);

%% Filter recording
N = length(data); % Number of samples in waveform
speech = data(:,1);
noise = data(:,2);
clearvars data

% Preallocate space
nbSpeech = nan(size(speech,1),nBands);
nbNoise = nan(size(noise,1),nBands);

% Filter
for kk = 1:1:nBands
    nbSpeech(:,kk) = fastFilter(OBFilters.(['band',num2str(kk)]),speech);
    nbNoise(:,kk) = fastFilter(OBFilters.(['band',num2str(kk)]),noise);
end

% Throw away ramped-on and -off sections
nbSpeech(1:nRamp,:) = [];
nbSpeech(end-nRamp+1:end,:) = [];
nbNoise(1:nRamp,:) = [];
nbNoise(end-nRamp+1:end,:) = [];

wbSpeech = sum(nbSpeech,2);
wbNoise = sum(nbNoise,2);

%% Calculate SNR for each band and across all bands
analysisWindow = .120; % Analysis window in seconds
analysisWindowN = ceil(analysisWindow*newFs);
N = size(nbSpeech,1);
nW = floor(N/analysisWindowN); % number of analysis windows in recording
for jj = 1:1:nBands
    
    % Narrowband Level Calculations
    tmpNbS = reshape(nbSpeech(1:analysisWindowN*nW,jj),analysisWindowN,nW);
    rmsNbS(:,jj) = sqrt(mean(tmpNbS.^2,1))'*(10^(levelCorr_dB/20));
%     rmsNbS(1,jj) = mean(sqrt(mean(tmpNbS.^2,1)),2);
    
    tmpNbN = reshape(nbNoise(1:analysisWindowN*nW,jj),analysisWindowN,nW);
    rmsNbN(:,jj) = sqrt(mean(tmpNbN.^2,1))'*(10^(levelCorr_dB/20));
%     rmsNbN(1,jj) = mean(sqrt(mean(tmpNbN.^2,1)),2);
        
end

% Wideband Level Calculations
tmpWbS = reshape(wbSpeech(1:analysisWindowN*nW),analysisWindowN,nW);
rmsWbS = sqrt(mean(tmpWbS.^2,1))'*(10^(levelCorr_dB/20));
%     rmsWbS = mean(sqrt(mean(tmpWbS.^2,1)),2);

tmpWbN = reshape(wbNoise(1:analysisWindowN*nW),analysisWindowN,nW);
rmsWbN = sqrt(mean(tmpWbN.^2,1))'*(10^(levelCorr_dB/20));
%     rmsWbN = mean(sqrt(mean(tmpWbN.^2,1)),2);

% Narrowband SNR
nbSNR.BarPa = 20*log10(mean(rmsNbS./rmsNbN,1));
nbSNR.BardB = mean(20*log10(rmsNbS./rmsNbN),1);
% Wideband SNR
wbSNR.BarPa = 20*log10(mean(rmsWbS./rmsWbN,1));
wbSNR.BardB = mean(20*log10(rmsWbS./rmsWbN),1);
% Frequency Vector
f = filterF;

%% Check to see whether an audiogram is avaiable
if audio == 1 % If audio, SII is calculated
    
    %% Prep for SII calculation
    % Change rms levels into spectrum levels:
    % For 1/3 octave band analysis spectrum level = rms - 10*log10(bw).
    % The 10*log10(bw) corresponds to "Bandwidth adj, delta dB" in Table 3 in
    % ANSI S3.5-1997.
    delta_dB = 10*log10(bwDesign); % roughly corresponds to Table 3, ANSI S3.5-1997
    E = 10*log10((mean(rmsNbS,1).^2)/(pref^2)) - delta_dB; % Speech spectrum level (dB SPL)
    N = 10*log10((mean(rmsNbN,1).^2)/(pref^2)) - delta_dB; % Noise spectrum level (dB SPL)
    
    %% SII Implementation
    % Convert thresholds in dB HL to dB SPL (not really necessary b/c they
    % are converted back to dB HL shortly but good for plotting...)
    THL = audiogram;
    TSPL = THL + RETSPLInsert;
    
    % Section 4.2 Step 2 - Equivalent speech, noise, and hearing threshold
    % spectra
    Ep = E - freeField2TM; % Equivalent speech spectrum
    Np = N - freeField2TM; % Equivalent noise spectrum
    Tp = TSPL - RETSPLInsert; % Equivalent hearing threshold spectrum is threshold (dB SPL) - MAP (dB SPL);
    
    % 4.3 Step 3 - Equivalent Masking Spectrum
    % 4.3.2 - 1/3 Octave Band Procedure
    % 4.3.2.1 Self-speech masking spectrum level (V)
    V = Ep - 24;
    % 4.3.2.2
    B = max(Np,V);
    % 4.3.2.3
    C = -80 + .6*(B + 10*log10(filterF) - 6.353);
    % 4.3.2.4
    Z = nan(1,nBands);
    for ii = 1:1:nBands
        if ii == 1
            Z(1,ii) = B(ii);
        else
            Z(1,ii) = 10*log10(10.^(.1*Np(ii)) + sum(10.^(.1*(B(1:ii-1) + 3.32*C(1:ii-1) ...
                .*log10(.89*filterF(ii)./filterF(1:ii-1))))));
        end
    end
    
    % 4.4 Step 4 - Equivalent Internal Noise Spectrum Level (Xp)
    Xp = X + Tp;
    
    % 4.5 Step 5 - Equivalent Disturbance Spectrum Level (D)
    D = max(Z,Xp);
    
    % 4.6 Step 6 - Level Distortion Factor (L)
    L = 1 - (Ep - UNormal - 10)/160;
    ind = L > 1;
    L(ind) = 1;
    
    % 4.7 Step 7 - Band Audibility Function (A)
    % 4.7.1
    K = (Ep - D + 15)/30;
    ind = K < 0;
    K(ind) = 0;
    ind = K > 1;
    K(ind) = 1;
    
    % 4.7.2
    A = L.*K;
    
    % 4.8 Step 8 - Speech Intelligibility Index (S)
    S = sum(I.*A);
    SIIData.SII = S;
    SIIData.wBandAud = A;
    %SIIData;
end



function [b] = buildOBFilters(fcLow,fcHigh,M,fs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function generates octave band filters according to user specified
% values:
%
% INPUT ARGUMENTS:
% f - filter center frequency (Hz)
% fcLow - low-side cutoff frequency (Hz; 6 dB down)
% fcHigh - high-side cutoff frequency (Hz; 6 dB down)
% M - filter order
% fs - sampling rate (Hz)
%
% OUTPUT ARGUMENTS:
% b - filter coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = fdesign.bandpass('N,Fc1,Fc2',M,fcLow,fcHigh,fs);
Hd = design(d);
b = get(Hd,'Numerator');
b = b';

function [y] = fastFilter(b,x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [y] = fastFilter(b,x)
%
% Function performs filtering in the frequency domain w/correction for
% group delay.  Matlab function fftfilt does not account for group delay.
%
% b - filter in frequency domain
% x - signal in frequency domain
%
% y - filtered signal in frequency domain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[row,col] = size(b);
if min([row,col]) == 1
    b = b(:);   % Forces vector into a column
end

if ~mod(size(b,1),2) % Check to see if filter order is even
    b = [b;zeros(1,size(b,2))];
    warning('Filter order is odd')
end

y = [];
M = size(b,1) - 1;
pad = zeros(round(M/2),size(x,2));
x = [x;pad];
y = fftfilt(b,x);
y = y(size(pad,1) + 1:end,:);