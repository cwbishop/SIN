function SIN_ClearErrors(err)
%% DESCRIPTION:
%
%   Function to assist in clearing and recovering from errors. This will
%   likely grow as SIN does and more and more error types are encountered.
%   For now, though, SIN will simply clear PsychPortAudio, close figures,
%   and close open 'Screens'
%
% INPUT:
%
%   err:    error code (currently unused)
%
% OUTPUT:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   8/14

%% CLOSE PSYCHPORTAUDIO
%   Running sounds will end
try
    PsychPortAudio('Close')
catch ME
    display('PTB: PsychPortAudio, no devices found'); 
end % 

%% CLOSE FIGURES
%   
close all 