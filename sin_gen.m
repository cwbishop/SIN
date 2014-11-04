function wave = sin_gen(hz, t, fs, ph)
%wave = sin_gen(hz, t, fs, ph)
%
%Generates a pure tone sine wave given the hz, duration (in seconds) and
%sampling frequency of the tone
%
%INPUTS:
%  hz - Frequency of the tone
%  t  - Tone duration in seconds
%  fs - Sampling rate, Defaults to 44100hz
%  ph - The starting phase of the tone. Defaults to 0.

if ~exist('ph') || isempty(ph)
    ph=0;
end

if ~exist('fs') || isempty(fs)
    fs=44100;
end

wave = sin([0:1/fs:t-1/fs]*hz*2*pi+ph)';