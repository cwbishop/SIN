function results = SIN_runTest(opts, playlist)
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
%   results:    results of the *last* test run in a sequence. Could be 
%               dangerous if users run a multipart test (e.g., ANL). Might
%               need to modify. 
%
% Development:
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
                
                % Check for errors after every step of test. 
                results = errorCheck(results, playlist); 
                
                % Save results to file 
                SIN_saveResults(results); 
                
            end % for i=1:length(opts)
            
        otherwise
            
            % If we don't have any special instructions, run
            % portaudio_adaptiveplay. 
            
            % Launch HINT (SNR-50)
            results = portaudio_adaptiveplay(playlist, opts); 
            
    end % switch/otherwise    
    
    % Save results to file 
    SIN_saveResults(results); 
    
end % for t=1:length(testID)

function results = errorCheck(results, playlist)
%% DESCRIPTION:
%
%   Function to check for and recover from errors following a test. If
%   error has occurred, prompt user for input on whether to continue
%   testing or to repeat the last test. 
%
% INPUT:
%
%   results:    results structure from previous test
%
%   playlist:   playlist used for test
%
% OUTPUT:
%
%   results:    results structure after appropriate action taken (if any).
%
% Christopher W Bishop
%   University of Washington
%   9/14

% Error checking
%   - If the player encounters an error for any reason, then we need to
%   give the user options on how to proceed. 
if isequal(results.RunTime.player.state, 'error')

    % First, run error clearing routine
    SIN_ClearErrors; 

    % We can just continue with testing
    resp = [];
    while isempty(resp) || isempty(strfind('cr', lower(resp)))
        resp = lower(input('Error encountered. Would you like to continue testing or repeat the last test/test segment? (C for continue, R for repeat)', 's'));
    end % while isempty

    % If user wants to continue anyway, then just return control to the
    % calling function. Otherwise, repeat the test. 
    if resp == 'c'
        return
    elseif resp == 'r'
        % Repeat the test
        results = SIN_runTest(results.UserOptions, playlist);         
    end % resp == c

end % if isequal ... error ...