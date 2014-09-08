function SIN_runTest(opts, playlist)
%% DESCRIPTION:
%
%   Master control function to run various tests associated with SIN. The
%   basic idea is to pass the function a unique test identifier (CWB is
%   thinking a string) that can be used to execute a specific set of
%   instructions. The upshot of this approach is that the same test can be
%   executed with ease from the commandline or via a GUI. 
%
% INPUT:
%
%   opts:       SIN test options structure returned from SIN_TestSetup.m
%
%   playlist:   *USE ONLY FOR DEBUGGING AND PROTOTYPING PURPOSES!*
%               Once you are finished debugging, update SIN_stiminfo to
%               return the playlist you want to use for this specific test.
%               
%               cell array, each element is the path to a wav file that
%               will be used in testing. In the context of SIN, this
%               information can generally be grabbed from SIN_stiminfo.m in
%               a fairly straightforward way. 
%   
%               Note: if playlist is empty, a playlist is generated using
%               SIN_getPlaylist. This
% OUTPUT:
%
%   None (yet) 
%
% Development:
%
%   2. Handle individual stage crashes better for ANL. Currently, if one
%   stage fails, the program just moves on. Need to have option to repeat
%   if we have an unusual exit status. This can also be said of all other
%   tests - runTest will need to be smarter in handling errors. 
%
%   3. Handle testID information better for multi-part tests (like ANL).
%   Currently, I just use the testID of the first element of opts. Works
%   for my needs, but might break (or have silent errors) in other
%   circumstances. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GET PLAYLIST
if ~exist('playlist', 'var') || isempty(playlist), [playlist, lists] = SIN_getPlaylist(opts(1)); end 

%% GET TESTID
%   Base running decisions on the testID of the first options structure.
%   Necessary for ANL and other multipart tests. Could be dangerous,
%   though, in other circumstances.
testID = {opts(1).specific.testID}; 

% Loop through all tests (eventually)
for t=1:length(testID)
        
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        
        case {'MLST'}
            
            error('Not functional'); 
            
        case {'ANL', 'ANL (MCL-Too Loud)', 'ANL (MCL-Too Quiet)', 'ANL (MCL-Estimate)', 'ANL (BNL-Too Loud)', 'ANL (BNL-Too Quiet)', 'ANL (BNL-Estimate)'}
            
            for i=1:length(opts)
                % Copy over relevant sections from previous tests.
                if i > 1
                
                    % Buffer Position
                    opts(i).player.startplaybackat = ...
                        results.RunTime.sandbox.buffer_pos./results.RunTime.player.playback.fs; 
                
                    % mod_mixer
                    %   Only want to copy over non-zero values. 
                    mixer_mask = results.RunTime.player.mod_mixer ~= 0; 
                    opts(i).player.mod_mixer(mixer_mask) = ...
                        results.RunTime.player.mod_mixer(mixer_mask); 

                    % Calibration information 
                
                end % if i > 1
            
                % Launch ANL (at least part of it) 
                %   We'll need to run this essentially 4 or 5 times and save
                %   the values in different files. 
                results = portaudio_adaptiveplay(playlist, opts(i));             
                                
                % Save results to file 
                SIN_saveResults(results); 
                
            end % for i=1:length(opts)
            
        otherwise
            
            % If we don't have any special instructions, run
            % portaudio_adaptiveplay. 
            
            % Launch HINT (SNR-50)
            results = portaudio_adaptiveplay(playlist, opts); 
            
            % Save results to file 
            SIN_saveResults(results); 
    end % switch/otherwise    
    
end % for t=1:length(testID)