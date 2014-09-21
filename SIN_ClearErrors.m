function SIN_ClearErrors(varargin)
%% DESCRIPTION:
%
%   Function to assist in clearing and recovering from errors. This will
%   likely grow as SIN does and more and more error types are encountered.
%   For now, though, SIN will simply clear PsychPortAudio, close figures,
%   and close open 'Screens'
%
%   Note: SIN_ClearErrors 
%
% INPUT:
%
%   'closerunSIN':  bool, close open runSIN window. If true, close.
%                   (default = false)
%
% OUTPUT:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   8/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

% PARAMETER CHECK
if ~isfield(d, 'closerunSIN') || isempty(d.closerunSIN), d.closerunSIN = false; end 

%% CLOSE PSYCHPORTAUDIO
%   Running sounds will end
try
    PsychPortAudio('Close')
catch
    display('PTB: PsychPortAudio, no devices found'); 
end % 

%% CLOSE FIGURES

% Get all open figures
figs = findobj('Type', 'figure'); 

% If user specifies, close the runSIN window. 
if ~d.closerunSIN
    % Find runSIN window
    rsin = findobj('Tag', 'runSIN');  
    
    % If rsin is empty, then the logic below throws a shoe. 
    if ~isempty(rsin)
        figs = figs(figs~=rsin);
    end 
else
    close(runSIN); 
end 

close(figs)

%% CLOSE KEYBOARD QUEUES
KbQueueStop;
KbQueueRelease;