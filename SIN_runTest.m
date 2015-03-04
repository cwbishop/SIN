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

% Loop through all tests (eventually)
for t=1:length(testID)
        
    % Display the test ID so the user knows which test and file name is
    % running
    display(['Running ' testID]);
    display(['Data saved to: ' opts(1).specific.saveData2mat]);         
    
    % Clear the previous results from the work space. These can be very
    % large and make tests run very sluggishly. Better to remove them prior
    % to run time.
    display('Clearing previous test results to improve performance');
    evalin('base', 'clear results'); 
    
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        
        case {'ANL', 'ANL (MCL-Too Loud)', 'ANL (MCL-Too Quiet)', 'ANL (MCL-Estimate)', 'ANL (BNL-Too Loud)', 'ANL (BNL-Too Quiet)', 'ANL (BNL-Estimate)'}
            
            for i=1:length(opts)
                
                %% GET PLAYLIST
                % Must get the playlist for each test in case individual
                % tests require a different test list
                
                % Append the data at run time. 
                %   Only append the "list" (if you can call it that) for
                %   the first section of the test. 
                if i == 1
                    opts(i).specific.genPlaylist.Append2UsedList = true;
                    [playlist, lists] = SIN_getPlaylist(opts(i));                
                    opts(i).specific.genPlaylist.Append2UsedList = false;                    
                else
                    
                    % Once we've loaded in the audio track ONCE, use the
                    % raw data as the playlist rather than the file name.
                    % This will save in file read/write times substantially
                    % since this is a large file.
                    %
                    % Christi asked CWB to speed up ANL, this is part of
                    % that solution. 
                    playlist = results(1).RunTime.sandbox.stim;
                    
                end % 
                
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
                
                % Stimulus cleanup
                %   We need to remove a few things from the data structure
                %   to decrease file size. 
                %       1. Remove sandbox.stim from RunTime. This is now
                %       redundant with sandbox.stim from first test
                %       segment.
                %
                %       2. Remove playback_list from RunTime. This is now
                %       100% redundant with stim in UserOpts.
                %
                %       3. Remove data2play_mixed. This is huge.
                %
                %       4. 
                if i > 1
                    results(i).RunTime.sandbox.playback_list = {}; 
                    results(i).RunTime.sandbox.stim = {};
                end % if i > 1 
                
            end % for i=1:length(opts)
        
        case {'HINT (Practice)', 'HINT (First Correct)', 'HINT (Perceptual Test, SPSHN)', 'HINT (SNR-50, SPSHN)', 'HINT (SNR-80, SPSHN)', 'HINT (SNR-50, ISTS)', 'HINT (SNR-80, ISTS)', 'HINT (Traditional, diotic)'};
            
            % Run HINT for SIN
            for i=1:numel(opts)
                
                %% GET PLAYLIST
                % Must get the playlist for each test in case individual
                % tests require a different test list
                
                % Conditional statement here handles used list tracking for
                % this specific set of tests. We only want to add when we
                % make it to the second test. 
                if i == 1
                    opts(i).specific.genPlaylist.Append2UsedList = true;
                else
                    opts(i).specific.genPlaylist.Append2UsedList = false;
                end % 
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
                 if i == 1
                    opts(i).specific.genPlaylist.Append2UsedList = true;
                else
                    opts(i).specific.genPlaylist.Append2UsedList = false;
                end % 
                    
                [playlist, ~] = SIN_getPlaylist(opts(i));
                
                % Run the stage
                results(i) = opts(i).player.player_handle(playlist, opts(i)); 
                
                % Check for errors after every stage of test. 
                results(i) = errorCheck(results(i), playlist); 
                
            end % for i=1:numel(opts)
            
    end % switch/otherwise    
    
%     % Run Analysis on the fly for spot checking??
%     %   We'll generally want to do this, CWB thinks. 
%     if results(1).RunTime.analysis.run
%         results = results(1).RunTime.analysis.fhand(results, results(1).RunTime.analysis.params);
%     end % if results(1).analysis.run
    
    %% Tell the user we're saving the data.
    
    % Estimate the size of the results structure
    var_info = whos('results');
    mbytes = var_info.bytes/(1000^2);
    
    display(['Saving results to file: ' opts(1).specific.saveData2mat]); 
    display(['Results are ' num2str(mbytes) ' MB in size']);
    
    % Let the user know this could take a while if it's over a GB. 
    if mbytes > 1000
        display('This might take a while. Please be patient'); 
    end 
    
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