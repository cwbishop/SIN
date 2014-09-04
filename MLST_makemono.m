function L = MLST_makemono(suffix)
%% DESCRIPTION:
%
%   Function to set one of the audio channels in MLST MP4 files to 0. MP4s
%   associated with MLST are stereo by default. We only want the audio to
%   play speech out of a single speaker. To do this, we'll edit the MP4s
%   using FFmpeg.
%
%   Download FFmpeg from here
%       https://ffmpeg.org/download.html
%
%   Make sure ffmpeg is added to your system path for robust execution of
%   the commands below.
%
%   Here's an example describing how to set a single channel in an MP4 file
%   to 0.
%
%   ffmpeg -i file.mp4 -filter_complex "pan=2c:c0=1*c0:c1=0*c0" -c:v copy
%   remix.rmp4
%
%   Note: 
%
%       CWB discovered that the zeroed out channels (0 in the pan setting)
%       can actually have some low-volume data present. Will need to deal
%       with this moving forward. 
%
%   To overwrite audio in MP4 with a different track, try something like
%   ...
%
%   ffmpeg -i 1_T5_046_HS.mp4 -i 2_T3_051_HS.mp3 -map 0:0 -map 1 -codec copy tmp.mp4
%
%
% INPUT:
%
%   suffix: string, what to append to file names after processing
%
% OUTPUT:
%   
%   Modified MP4s for MLST.
%
% Christopher W. Bishop
%   University of Washington
%   8/14

warning('CWB discovered there is low-amplitude data in removed channel'); 

%% GET THE PLAY LIST FOR MLST
opts = SIN_TestSetup('MLST (AV)', '');

%% GET STIMULUS LIST (MP4s)
[~, mp4s] = SIN_stiminfo(opts); 
L=[];
for d=1:numel(mp4s)
    
    files = mp4s{d};
    
    for f=1:numel(files)
        
        % Read in audio data
        % Get path, file, extension information
        [PATHSTR,NAME,EXT] = fileparts(files{f});
        
        % This command leads to changes in AV alignment of ~30 ms (~ 1
        % frame at 29.97 FPS). Maybe negligible, but maybe not. Let's see
        % if we have better AV preservation.        
        % frames)
        ofile = fullfile(PATHSTR, [NAME suffix EXT]);
%         cmd = ['ffmpeg -i "' files{f} '" -filter_complex "pan=2c:c0=1*c0:c1=0*c0" -c:v copy "' ofile '"'];
        cmd = ['ffmpeg -i "' files{f} '" -filter_complex "pan=2c:c0=1*c0:c1=0*c0" -c:v copy "' ofile '"'];
        % Run at command line
        system(cmd, '-echo'); 

        % Read in audio data from original and edited file
        [orig, ofs] = audioread(files{f}); 
        [edited, efs] = audioread(ofile); 
        
        % Align timeseries and collect temporal offset information.
        [~, ~, l] = align_timeseries(orig(:,1), edited(:,1), 'xcorr', 'fsx', ofs, 'fsy', efs, 'pflag', 1);
        L = [L; l./ofs]; % collect lag information (in sec)
        
        % Plot channel 2 as well
        h=figure; 
        hold on
        title('Channel 2');
        plot_waveform(orig(:,2), ofs, 'k', 2, h);
        plot_waveform(edited(:,2), efs, 'r', 1, h);
        legend('Original', 'Edited')
       
        display(L(end)); 
        input('Continue?');
        close all       
        
    end % for f=1:numel(files)
end % d=1:numel(mp4s)

figure, hist(L); 
