function SIN_saveResults(results)
%% DESCRIPTION:
%
%   Basic function to save results. This was originally written to save
%   results from portaudio_adaptiveplay, but shouldn't be difficult to
%   expand to various results formats.
%
% INPUT:
%
%   results:    portaudio_adaptiveplay results structure
%
% OUTPUT:
%
%   Saved mat file
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% GET RUNTIME OPTIONS
%   - This will return the most "up-to-date" information. It's possible
%   that the player (or a modifier attached to the player) will change a
%   relevant field. So we want to work with that rather than the
%   UserOptions.
opts = results.RunTime; 

%% FILE NAME
%
%   - The file name is a combination of the subject ID, test ID, and the
%   UUID. This generates what CWB hopes is a unique and informative file
%   name that will make it easy for users to collect data for analysis
%   purposes later.
%
%   Results will be placed in the appropriate test folder within
%   subject_data (or wherever data are stored). 
% fname = fullfile(opts.subject.subjectDir, opts.specific.testID, [opts.subject.subjectID '-' opts.specific.testID '-' opts.specific.uuid]);
fname = opts.specific.saveData2mat; 

%% SAVE RESULTS
save(fname, 'results');