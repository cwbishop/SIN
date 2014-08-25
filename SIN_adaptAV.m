function fliptimes = SIN_adaptAV(deviceID)
%% DESCRIPTION:
%
%   Test function for loading and presenting audiovisual files in sync. 
%
% INPUT:
%
% OUTPUT:
%
% Christopher W. Bishop
%   University of Washington
%   08/14

%% LOAD INFORMATION FROM SIN
%   Just use a dummy subject for now
opts = SIN_TestSetup('MLST (AV)', ''); 

%% GET A PLAYLIST
%   Returns the filenames for playback. We really only need one file
playlist = SIN_getPlaylist(opts); 

% Read in videos and audio
% X = SIN_loaddata(playlist); 

% moviename = playlist{1};
% Hard code movie name for consistent testing
moviename=fullfile('C:\Users\cwbishop\Documents\GitHub\SIN\playback\MLST (Adult)\List_01', '1_T5_046_HS.mp4');

%% GET AUDIO DATA
[aud, afs] = audioread(moviename); 

%% OPEN AUDIO PLAYBACK DEVICE
[pstruct]=portaudio_GetDevice(opts.player.playback.device);
FS = opts.player.playback.device.DefaultSampleRate; 

% Resample audio.
%   - The MP4s are sampled at 48 kHz, while MP3s are sampled at 44.1 kHz.
%   - Need to resample to whatever the playback device wants (M-Audio wants
%   44.1 kHz).
aud = resample(aud, FS, afs); 

% add in missing audio channels
aud = [aud zeros(size(aud,1), pstruct.NrOutputChannels - size(aud,2))];

% Set buffer to length of playback sound. 
phand = PsychPortAudio('Open', pstruct.DeviceIndex, 1, 0, pstruct.DefaultSampleRate, pstruct.NrOutputChannels, opts.player.playback.internal_buffer);

% Fill buffer with zeros
%   This is just used to initialize sound playback
PsychPortAudio('FillBuffer', phand, zeros(size(aud,1), pstruct.NrOutputChannels)');

% Initialize - playthrough buffer once completel 
%   Might need to change this so we don't have a variable delay based on
%   the audio length. But really, for clinical tests, this is probably
%   fine.
PsychPortAudio('Start', phand, 1, 0, 1);
PsychPortAudio('Stop', phand, 1);

% Now, load the audio track into the buffer
PsychPortAudio('FillBuffer', phand, aud');

% Try setting a latency bias ... see if this affects things
%   This setting DOES affect the start of sound playback. Positive values
%   delay sound playback, negative values advance soundplayback (to a
%   limit ... informal testing suggests that we need at least 20 ms to
%   initialize sound playback). 
% PsychPortAudio('LatencyBias', phand, -10); % set latency bias as something outrageously high.
% Load video frames
obj = VideoReader(moviename);

vid = read(obj); % these are the frames in AxBx3xN, where A/B are the dimensions and N is the number of frames

% Temporal interpolation of video playback
%   - Used to convert between temporal sampling rates.
%   - This necessarily uses interpn, since resample only accepts integers
%   ratios. Interp1 isn't as good (there will be some slop), but should be
%   more robust to weird sampling rates (like 29.97 fps, which is common)
% ofps = obj.FrameRate;

% tfps = 60; % We want to target 60 Hz

% tvid = []; 

% Stole code from here 
%   https://psychtoolbox.org/bitsplusplustypicalscript
whichScreen=max(Screen('Screens'));
[window,screenRect] = Screen('OpenWindow',whichScreen);

% Set monitor refresh rate
% hz=Screen('NominalFrameRate', window, 2, 60);

% Get monitor refresh rate (in sec)
ifi = Screen('GetFlipInterval', window);

% Convert all video frames to textures
%   - We'll double the frame number to target ~60 Hz
textureIndex =[];
for i=1:size(vid,4)
    
    % Load same frame twice for ~60 Hz playback
    textureIndex(end+1) = Screen( 'MakeTexture', window, vid(:,:,:,i) );
    textureIndex(end+1) = textureIndex(end); % copy the texture index over
%     textureIndex(end+1) = Screen( 'MakeTexture', window, vid(:,:,:,i) );
    
end % for i

% This should load the textures ...
% tic;
% [textureIndex, runtime] = SIN_video2texture({moviename}, 'window', window);
% toc
% Screen('CloseAll'); 
% textureIndex = textureIndex{1}; % convert from cell
% Close the screen for testing
% 

[vbl1 visonset1]= Screen('Flip', window);

% This Should present the first image in the movie sequence.
% Screen('DrawTexture', window, textureIndex(1));
% Screen('DrawingFinished', window);

% Schedule time of first frame
% suggestedLatencySecs = 5;
% waitframes = ceil((2 * suggestedLatencySecs) / ifi) + 1;

% [vbl visual_onset t1] = Screen('Flip', window, vbl1 + (waitframes - 0.5) * ifi);

% Schedule start of audio at exactly the predicted visual stimulus
% onset caused by the next flip command.
% PsychPortAudio('Start', phand, 1, visonset1 + waitframes * ifi, 0);

% Loop through video frames
fliptimes = [];
for i=1:numel(textureIndex)    
    
    % Forget about waiting, just start playback.
    Screen('DrawTexture', window, textureIndex(i));    
    fliptimes(i)=Screen( 'Flip', window, 0, 0 );  
    
    % Immediate soundplayback start
    %   Play through buffer once. 
    if i==1
        tic;
        % Start playback, go ahead and wait for start of playback (5th
        % input)
        %   This (should) force the first frame to stay on the screen until
        %   the sound has started (CWB thinks, at least).
        PsychPortAudio('Start', phand, 1, 1, 1);
%         PsychPortAudio('Start', phand, 1, 1, 0);
        toc
        status = PsychPortAudio('GetStatus', phand);
        display(status.Active)
        audio_onset = status.StartTime;
    end % 
    
    % Might need to update the status of the playback device if it wasn't
    % yet initiated
    if status.Active~=1
        status = PsychPortAudio('GetStatus', phand);
    end % 
end

% fprintf('Screen    expects visual onset at %6.6f secs.\n', visual_onset);
% fprintf('PortAudio expects audio onset  at %6.6f secs.\n', audio_onset);
% fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (audio_onset - visual_onset)*1000.0);

% Clean up
Screen('CloseAll');
PsychPortAudio('Close');