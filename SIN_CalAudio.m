function SIN_CalAudio(REF, varargin)
%% DESCRIPTION:
%
%   The calibration procedure for SIN sets the HINT-Noise.wav (a speech
%   shaped noise sample) to 0 dB and scales all other stimuli or stimulus
%   sets to also rest at 0 dB. The user can then present the HINT-Noise
%   stimulus through their sound playback system and adjust (via hardware)
%   the sound pressure level (SPL) to the desired level. Following this
%   procedure, all stimuli/stimulus sets should be have a nearly identical
%   SPL, provided that the frequency response of the playback/recording
%   loop is flat (enough). CWB recommends using hardware (e.g., a graphical
%   equalizer) to flatten the frequency response of your playback/recording
%   loop. 
%
% INPUT:
%
%   REF:    path to reference file. (e.g., fullfile('playback', 'Noise', 'HINT-Noise.wav'))
%
% Parameters:
%
%   'testID':   string, testID used in call to SIN_TestSetup that is then
%               used to gather stimulus information 
%               
%   'nmixer':   Nx1 scaling matrix, where N is the number of data channels
%               in the reference signal (typically 2x1 for HINT-Noise.wav) 
%
%   'targetdB': double, the relative decibel level to scale output stimuli
%               to. This is useful if, for instance, the reference sound is
%               calibrated to 65 dB, but the user wants the remaining sound
%               files to be calibrated to 80 dB. In this example,
%               'targetdB' would be +15. 
%
%   'removesilence':    bool, remove silence from beginning and end of
%                       sounds. If true, requires ampThresh argument below.
%                       CWB generally recommends this since excess silence
%                       at beginning and end of sounds can reduce RMS
%                       estimates considerably (and variably) depending on
%                       the length of the silent period. 
%
%   'ampthresh':    used to remove silence from beginning and end of
%                   acoustic waveforms prior to RMS estimation. 
%
%   'bitdepth': bit depth for written audio files. Note: CWB is not sure if
%               this applies to MP4s since these invoke FFmpeg for scaling
%               purposes. 
%
%   'suffix':   string to append to end of file name for newly created
%               files.
%
%   'tmixer':   Dx1 scaling matrix, where D is the number of data channels
%               in the to-be-calibrated target files. The code will
%               essentially combine (linearly) data from the D channels in
%               each file. These data are then used (perhaps with some
%               additional processing) to estimate the RMS of the target
%               file.
%
%   'omixer':   1xP scaling matrix, where 1 is the number of data channels
%               (the result of .tmixer) and P is the number of output
%               channels in the generated file (.wav or .mp4). 
%
% Development:
%
%   1) Add a "calibrate by channel" option. This will likely be necessary
%   for ANL since the two tracks differ by 0.4 dB. Or we can just assume
%   it's OK, use the raw materials we have, and then say "well, we're wrong
%   the same way that everyone else is wrong". I hate that, but maybe
%   better than mucking with things here?
%
% Christopher W. Bishop
%   University of Washington
%   9/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% GET TEST INFORMATION
%   The general field also has information we'll need regarding the
%   location of noise files. 
opts = SIN_TestSetup(d.testID, ''); 

%% LOAD THE REFERENCE NOISE
[ref_data, FS] = audioread(REF);

%% SCALE NOISE
ref_data = ref_data*d.nmixer; 

%% WRITE CALIBRATED STIMULI
%   - Now, we load in the stimuli for the specific test we want to rewrite
%   stimuli for. 
%   - Grab file names
[~, files] = SIN_stiminfo(opts);

%% LOAD ALL FILES IN STIMULUS LIST
%   - Load all files, concatenate into larger file for RMS estimation
concat = [];
fs = [];
for i=1:numel(files)
    
    % Loop through files
    for k=1:numel(files{i})
        
        % Load data file
        [data, nfs] = audioread(files{i}{k}); 
        
        % Apply appropriate mixer
        %   This should reduce the data to a single channel. 
        data = data*d.tmixer;
        
        % Sampling rate check
        if isempty(fs)
            fs = nfs;
        elseif fs ~= nfs
            error('Sampling rates do not match');
        end % if isempty(fs)
        
        % Remove silence?
        if d.removesilence
            data = threshclipaudio(data, d.ampthresh, 'begin&end');
        end % if d.removesilence
        
        % Concatenate data
        %   Apply mixer to data as well. Should reduce data to single
        %   channel. 
        concat =[concat; data]; 
        
    end % for k=1:numel(files{i})
    
end % for i=1:length(files)

%% CALCULATE SCALING FACTOR
%   Identical scaling factor should be applied to all stimuli from the same
%   test. 
scale = db2amp(db(rms(ref_data)) - db(rms(concat)) + d.targetdB);

%% APPLY SCALING FACTOR, WRITE STIMULI
%   Now, load/scale each stimulu, write to file. 
for i=1:numel(files)
    
    for k=1:numel(files{i})
        
        % We need to do something different depending on the file format. 
        [PATHSTR,NAME,EXT] = fileparts(files{i}{k});        
        
        % Create output file name
        fout = fullfile(PATHSTR, [NAME d.suffix EXT]);  
        
        % If a .wav/.mp3, then use audiowrite
        switch EXT
            
            case {'.wav' '.mp3'}
                
                % Read in audio data
                [data, fs] = audioread(files{i}{k});
                
                % Apply tmixer
                %   Need to apply this again since we applied it to
                %   estimate the scaling factor. Also helps us create
                %   monaural files (i.e., without noise!)
                data = data * d.tmixer; 
                
                % Scale audio data
                data = data.*scale; 
                
                % Rewrite to file                               
                audiowrite(fout, data, fs, 'BitsperSample', d.bitdepth); 
                
            case {'.mp4'}
                
                %% NOTE:
                %   CWB tried a direct call to FFmpeg with channel scaling
                %   parameters, but there were data still present in zeroed
                %   out channels. Sounded like high frequency squeaking
                %   when played with soundsc. Could not be heard on his PC
                %   with wavplay or equivalent (unscaled) playback.
                %
                %   CWB will now try an intermediary step to write a wav
                %   file, then replace the audio track of the MP4 with the
                %   (correctly zeroed) Wav file
%                 % Create command string                
                cmd = ['ffmpeg -i "' files{i}{k} '" -filter_complex ' mixer2pan((d.tmixer.*scale)*d.omixer) ' -c:v copy "' fout '"'];
                
                % Read in audio data
%                 [data, fs]=audioread(files{i}{k}); 
%                 
%                 % Scale data
%                 data = ((data*d.tmixer).*scale)*d.omixer;
%                 
%                 % Write temporary wav file)
%                 temp_file = fullfile(PATHSTR, [NAME d.suffix '.mp4']);
% %                 audiowrite(temp_file, data, fs, 'BitsperSample', d.bitdepth);
%                 audiowrite(temp_file, data, fs);
                % Now replace audio track 
%                 % Execute command
%                 system(cmd, '-echo'); 
                
            otherwise
                error('Unknown file extension');
        end % switch EXT
        % If MP4, then use FFmpeg (see MLST_makemono for details)
        
    end % for k=1:numel(files{i})
end % for i=1:numel(files)
