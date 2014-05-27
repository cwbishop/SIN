function SIN_runTest(testID, subjectID, opts, play_list)
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
%   subjectID:  string, subject ID.
%
%   testID:     cell containing the test ID. CWB opted to used a cell here
%               in case he later wants to use a test list (meaning, running
%               a sequence of tests in a specific order - perhaps a
%               randomized order). Alternatively, testID can be a string.
%               This will be automatically converted to a cell within the
%               function.           
%
%   subjectID:  string, subject identifier. There is absolutely no error
%               checking in place here. If the user wants to validate a
%               subject ID, see SIN_register_subject. 
%
%   opts:       SIN test options structure returned from SIN_TestSetup.m
%
%   play_list:  cell array, each element is the path to a wav file that
%               will be used in testing. In the context of SIN, this
%               information can generally be grabbed from SIN_stiminfo.m in
%               a fairly straightforward way. 
%
% OUTPUT:
%
%   None (yet) 
%
% Development:
%
%   1) Complete ANL test administration.   
%
%   2. Handle individual stage crashes better for ANL. Currently, if one
%   stage fails, the program just moves on. Need to have option to repeat
%   if we have an unusual exit status. This can also be said of all other
%   tests - runTest will need to be smarter in handling errors. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% TEST ID CHECK
%   Convert testID to a cell. CWB has tentative plans to allow the user to
%   run a host of tests in sequence. So testID is coded as a cell here to
%   allow that possibility in the future. 
% Convert char to cell
if ischar(testID)
    testID={testID};
end % if ischar

% Input checks
%   Currently we only allow for a single test to be run at a time.
%
%   Notice that CWB does not do a basic options check here. The user *must*
%   supply the test option information. We don't want to accidentally run a
%   test the user did not intend or with settings that differ from what the
%   user wanted. So, force the user (or GUI) to provide this information 
% if numel(testID)~=1, error('Incorrect number of testIDs'); end 
% if numel(opts) ~= numel(testID), error('Not enough options structures for tests'); end

%% SUBJECT ID ERROR CHECK
%   Make sure subject ID conforms to generalized pattern

%% CALIBRATION ERROR CHECK
%   Make sure the calibration file fits whatever validation criteria we lay
%   out (probably date dependent, etc.).

%% MAKE SURE DIRECTORIES ARE IN PLACE
%   Should be handled by SIN_register_subject

% Loop through all tests (eventually)
for t=1:length(testID)
        
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        
        case {'HINT (SNR-50)', 'PPT'}
            
            % Launch HINT (SNR-50)
            results = portaudio_adaptiveplay(play_list, opts); 
            
            % Save the subject ID to sandbox
            results.RunTime.sandbox.subjectID=subjectID;
            
        case {'ANL'}
            
            for i=1:length(opts)
                % Copy over relevant sections from previous tests.
                if i > 1
                
                    % Buffer Position
                    opts(i).player.startplaybackat = ...
                        results.RunTime.sandbox.buffer_pos./results.RunTime.player.playback.fs; 
%                         opts(i-1).sandbox.buffer_pos;
                
                    % mod_mixer
                    opts(i).player.mod_mixer = ...
                        results.RunTime.player.mod_mixer; 
                
                    % Calibration information 
                
                end % if i > 1
            
                % Launch ANL (at least part of it) 
                %   We'll need to run this essentially 4 or 5 times and save
                %   the values in different files. 
                results = portaudio_adaptiveplay(play_list, opts(i)); 
            
                % Save the subject ID to sandbox
                results.RunTime.sandbox.subjectID=subjectID;
                
                % Save results to file 
                save(fullfile(opts(i).general.subjectDir, subjectID, testID{t}, [subjectID '-' opts(i).specific.testID]), 'results'); 
                
            end % for i=1:length(opts)
                        
        case {'MLST'}
            
        case {'Hagerman'}
            
        otherwise
            
            error(['Unknown test ID: ' testID{t}]); 
            
    end % switch/otherwise
    
    % Save results to file 
    save(fullfile(opts(t).general.subjectDir, subjectID, testID{t}, [subjectID '-' testID{t}]), 'results'); 
    
end % for t=1:length(testID)