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
%   results:    results structure. May be single element or multi-element
%               depending on how the test is configured/run. 
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GET TESTID
%   Base running decisions on the testID of the first options structure.
%   Necessary for ANL and other multipart tests. Could be dangerous,
%   though, in other circumstances.
testID = {opts(1).specific.testID}; 

%% INITIALIZE RETURN VARIABLES
allresults = struct(); % structure containing results information for each test/test stage. 

% Loop through all tests (eventually)
for t=1:length(testID)
        
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        
        case {'ANL', 'ANL (MCL-Too Loud)', 'ANL (MCL-Too Quiet)', 'ANL (MCL-Estimate)', 'ANL (BNL-Too Loud)', 'ANL (BNL-Too Quiet)', 'ANL (BNL-Estimate)'}
            
            for i=1:length(opts)
                
                %% GET PLAYLIST
                % Must get the playlist for each test in case individual
                % tests require a different test list
                [playlist, lists] = SIN_getPlaylist(opts(i));
                
                % Copy over relevant sections from previous tests.
                if i > 1
                
                    % Buffer Position
                    opts(i).player.startplaybackat = ...
                        results(i-1).RunTime.sandbox.buffer_pos./results(i-1).RunTime.sandbox.playback_fs; 
                
                    % mod_mixer
                    %   Only want to copy over non-zero values. 
                    mixer_mask = results(i-1).RunTime.player.mod_mixer ~= 0; 
                    opts(i).player.mod_mixer(mixer_mask) = ...
                        results(i-1).RunTime.player.mod_mixer(mixer_mask); 

                    % Calibration information 
                
                end % if i > 1
            
                % Launch ANL (at least part of it) 
                %   We'll need to run this essentially 4 or 5 times and save
                %   the values in different files. 
                results(i) = opts(i).player.player_handle(playlist, opts(i));
                
                % Check for errors after every step of test. 
                results(i) = errorCheck(results(i), playlist); 
                
            end % for i=1:length(opts)
        
        case {'HINT (First Correct)', 'HINT (Perceptual Test)', 'HINT (SNR-50, keywords, 1up1down)', 'HINT (SNR-80, keywords, 4down1up)'};
            
            % Run HINT for SIN
            for i=1:numel(opts)
                %% GET PLAYLIST
                % Must get the playlist for each test in case individual
                % tests require a different test list
                [playlist, ~] = SIN_getPlaylist(opts(i));
                
                % Every other test should inherit the mod_mixer from the
                % test before it
                if mod(i, 2) == 0
                    opts(i).player.mod_mixer = results(i-1).RunTime.player.mod_mixer;
                end % if mod(i, 2) == 0
                
                % Run the stage
                results(i) = opts(i).player.player_handle(playlist, opts(i)); 
                
                % Check for errors after every stage of test. 
                results(i) = errorCheck(results(i), playlist); 
                
            end % end 
            
        otherwise
            
            % If we don't have any special instructions, run
            % portaudio_adaptiveplay. 
            
            % Launch whatever the specified player is
            %   Need the loop in case we encounter multi-stage tests that
            %   do not have any special instructions. 
            for i=1:numel(opts)
                
                % Create playlist. Do this for each stage of the test
                % separately. 
                [playlist, ~] = SIN_getPlaylist(opts(i));
                
                % Run the stage
                results(i) = opts(i).player.player_handle(playlist, opts(i)); 
                
                % Check for errors after every stage of test. 
                results(i) = errorCheck(results(i), playlist); 
                
            end % for i=1:numel(opts)
            
    end % switch/otherwise    
    
    % Run Analysis on the fly for spot checking??
    %   We'll generally want to do this, CWB thinks. 
    if results(1).RunTime.analysis.run
        results = results(1).RunTime.analysis.fhand(results, results(1).RunTime.analysis.params);
    end % if results(1).analysis.run
    
    % Save to results file
    %   Results should have whatever data are explicitly stored in the
    %   analysis phase as well. 
    SIN_saveResults(results); 
    
    % Assign results to the top-level workspace
    assignin('base', 'results', results); 
    
    % Close remaining GUIs and make sure all errors are cleared
    SIN_ClearErrors; 
end % for t=1:length(testID)

% Save allresults structure instead??

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
if isfield(results.RunTime.player, 'state') && isequal(results.RunTime.player.state, 'error')

    % First, run error clearing routine
    %   But don't close runSIN. Leave that open so the user can still run
    %   tests.
    SIN_ClearErrors('closerunSIN', false); 

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
        %   Set analyes to false, since we'll run it again when we return
        %   results to SIN_runTest
        opts = results.UserOptions;
        opts.analysis.run = false; 
        
        results = SIN_runTest(opts, playlist);         
    end % resp == c

elseif ~isfield(results.RunTime.player, 'state')
    warning('Player state unknown. Assuming no errors occurred'); 
end % if isequal ... error ...