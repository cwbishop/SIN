function [Psm,fxx] = logsmooth(Pxx,fxx,oct,smin)
% LOG SMOOTH
%       Gaussian spectral smoothing filter with smoothing kernel width increasing
%       logarithmically with frequency.  It's ungodly ineffiecient due to the
%       anisotropic smoothing, so it downsamples spectrum to "nout" points.
%       Smooths in log-log (frequency-magnitude) space. Assumes fxx from 0 to Nyquist
%       and Pxx  magnitude on a linear scale (not 10*log10), so it works well with
%       output from pwelch.  It doesn't know anything about phase.
%       Power values equal to zero are changed to eps.
%
% INPUTS
%   Pxx     power spectrum magnitude (linear scale)
%   fxx     frequency array for Pxx, must be monotonically increasing, same
%           length as Pxx
%   nout       number of points in a logarithmic, smoothed output
%            Default = 300
%   oct     width, in octaves, of the smoothing kernel, subject to smin.
%            Default = 1/10
%   smin    minimum number of points to include in a kernel, must be odd.
%           Larger numbers keep signal smoother at very low frequencies.
%               Default = 101
% OUTPUTS
% Psm       smoothed power spectrum
% fxxms     frequency array for plotting Psm
%
%            [Psm,fxxsm] = logsmooth(Pxx,fxx,oct,smin);
%
% MillerLM 01/07


fmin = 20;


%input checks
if nargin<4
    smin = 101;
end
if nargin < 3
    oct = 1/10;
end

if oct > 0.5
    warning('Broad smoothing kernel may shift peaks or have weird edge effects.  Reduce smoothing to < 0.5 octaves')
end

% set zero powers to tiny number, so can take log
Pxx(find(abs(Pxx)<eps)) = eps;

% set oversampling ratio
nup = 20;
nout = log2(fxx(end)/fmin) * nup;  %resample in octaves at appx. nup times the filter width

if rem(smin,2) == 0
    smin = smin + 1;
    disp('Made smin odd')
end


PxxdB = 10*log10(Pxx);  % so smoothing occurs in log amplitude

% gaussian kernel
grange = 2;
xg = [-grange:.01:grange];
g = gaussmf(xg,[1 0]);
%
% grange = 2;
% xg = [.01:.01:2*grange];
% g = gaussmf(xg,[1 grange]);

% reflect ends of spectrum to avoid edge effects
PxxrdB = [flipud(PxxdB); PxxdB; flipud(PxxdB)];
offset = length(PxxdB);
fxxincr = fxx(end)-fxx(end-1);
fxxr = [zeros(offset,1)' fxx' fxx(end)+fxxincr.*[1:offset]];

% loop through and 'convolve' each point with ever larger smoothing kernels
h2 = figure;, hold on
istart = offset+1;
iend = 2*offset;
ieval = round(logspace(log10(istart-offset),log10(iend-offset),nout))+offset;  %could also make this lin spaced
if fxxr(istart)==0  % if freq array starts at DC
   fxxsm = [0 logspace(log10(fxxr(istart+1)),log10(fxxr(iend)),length(ieval)-1)];
   PxxrDC = PxxrdB(istart);
   PxxrdB(istart) = PxxrdB(istart+1);
else
   fxxsm = [logspace(log10(fxxr(istart)),log10(fxxr(iend)),length(ieval))];
end
norep = [1 find(diff(ieval)~=0)+1];
ieval = ieval(norep);
fxxsm = fxxsm(norep);

% Make smoothed signal
PsmdB = zeros(length(ieval),1);
for i = 1:length(ieval)
   iieval = ieval(i);
   fspan = fxxr(iieval) - fxxr(iieval)*2^-(oct*2);
   fmin = fxxr(iieval) - fspan;
   fmax = fxxr(iieval) + fspan;
   ifmin = min(find(fxxr>fmin));
   ifmax = max(find(fxxr<fmax));

   n = ifmax - ifmin + 1;
   if n > smin
       glin = linspace(-grange,grange,n);
       %glin = logspace(log10(xg(1)),log10(xg(end)),n);
       gspline = interp1(xg,g,glin,'spline');
       gspline = gspline./sum(gspline);
       PsmdB(i) = gspline * PxxrdB(ifmin:ifmax);
   else
       glin = linspace(-grange,grange,smin);
       %glin = logspace(log10(xg(1)),log10(xg(end)),smin);
       gspline = interp1(xg,g,glin,'spline');
       gspline = gspline./sum(gspline);
       PsmdB(i) = gspline * PxxrdB(iieval-floor(smin/2):iieval+floor(smin/2));  % enforce at least smin-point smoothing
   end
end


if fxxr(istart)==0
   disp('Took out DC during smoothing and replaced with original value')
   PsmdB(1) = PxxrDC;
end


% plot
figure(h2);
plot(fxx,PxxdB,'r')
plot(fxxsm,PsmdB,'g')
set(gca,'Xscale','log')

Psm = 10.^(PsmdB/10);  %revert to linear amplitude, as with input Pxx

%Psm = interp1(fxxsm,Psm,fxx,'spline');
Psm = interp1(fxxsm,Psm,fxx,'pchip');  %pchip is more graceful at abrupt boundaries than spline