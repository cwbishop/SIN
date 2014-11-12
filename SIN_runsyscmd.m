function results = SIN_runsyscmd(pl, varargin)
%% DESCRIPTION:
%
%   Wrapper function to handle and run system commands. This is used as a
%   "player" to run executables and the like.
%
% INPUT:
%
%   pl:  a placeholder to conform to player conventions in SIN. Kind of
%        silly, really
%
%   SIN options structure with the following fields in the 'player'
%   subfield.
%
%   'cmd':  string, command to run at the command line. 
%
%   Alternatively, inputs can be a structure with the corresponding
%   fieldnames/values, OR a list of key/value pairs. Any should work.
%
% OUTPUT:
%
%   None (Yet)
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GATHER KEY/VALUE PAIRS
d=varargin2struct(varargin{:}); 

%% ARE WE USING A SIN STRUCTURE?
if ~isfield(d, 'player')
    d.player = d; % force it to look like a SIN options structure
end % if ~isfield( ...

%% RESULTS
results.UserOptions = d;

%% ADD START_TIME
d.sandbox.start_time = now; 

%% RUN SYSTEM COMMAND
system(d.player.cmd); 

%% ADD END TIME
d.sandbox.end_time = now;

%% ASSIGN TO RunTime field. 
results.RunTime = d; 
