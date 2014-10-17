%fftplot(x,Fs)
%x = signal vector
%fs = sampling rate

function fftplot(x,Fs,col, fn)

% TRACE COLOR
if ~exist('col', 'var') || isempty(col), col = 'b'; end
if ~exist('fn', 'var') || isempty(fn)
    figure;
else
    figure(fn);
    hold on
end % ;

%% FFT Decomp
n = length(x);
y = fft(x)/n;
f = Fs/2*linspace(0,1,n/2+1);

% Convert to power
% power = abs(y(1:floor(n/2)+1)).^2; power=10*log10(power); 
amp=(2*abs(y(1:n/2+1))); % convert to single-sided amplitude measure
ampdb=20*log10(amp); % convert to dB
plot(f,ampdb,col);
% figure, plot(f,power,col);
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)');


