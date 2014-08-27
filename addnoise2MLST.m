function addnoise2MLST
%% DESCRIPTION:
%
%   This function adds a specified noise file to the MLST MP4 corpus. This
%   is done using the following procedure:
%
%       1. Remove existing audio from MP4s using MATLAB's "audioread"
%       function. 
%
%       2. Zero the audio to match the video length after it's encoded. 
%
%       3. Add noise (speech shaped or ISTS) to the audio track. 
%
%       3. Replicate the first frame of the video to account for noise lead
%       time.
%
%       4. Replicate 

% Here's a link on how to repeat the first frame of a video using FFmpeg to
% compensate for longer audio
%   http://stackoverflow.com/questions/18607386/repeating-the-first-frame-of-a-video-with-ffmpeg