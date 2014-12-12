function [mod_code, d] = modcheck_wordspan_gui(varargin)
%% DESCRIPTION:
%
%   A modification check that calls WordSpan_GUI for scoring purposes. This
%   is similar in use and function to modcheck_HINT_GUI, but uses a
%   specialized scoring GUI. 
%
% INPUT:
%
% Parameters:
%
%   None(yet) ...
%
% OUTPUT:
%
%   mod_code:   modification code. Always returns a 0 since no
%               modifications are necessary.
%
%   d:  updated player options structure.
%
% Development:
%
%   None (yet).
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% INPUT CHECK AND DEFAULTS

% Initialize mod_code
%   mod_code will always be 0 for this modification check. 
mod_code=0;

%% INPUT ARGS TO STRUCTURE
d=varargin2struct(varargin{:});

% This *should* allow the user to call this function from other players as
% well or from the command line, but neither have been tested by CWB. 
if ~isfield(d, 'player')
    d.player=d; 
end % opts

% This execute the first time the modcheck is called from player_main
if ~isfield(d.player.modcheck, 'initialized'), d.player.modcheck.initialized = false; end

% Have we initialized the modcheck yet? If not, do the following ...
%   - Load the lookup table
%   - set initialized to true
%   - Initialize score_data field, which will hold the scored data
%   information on a trial-by-trial basis
if ~d.player.modcheck.initialized
    
    % Load lookup table
    d.player.modcheck.table = load_lookup_table( d.player.specific.lookup_table);
%         'path_to_table', d.player.specific.lookup_table, ...
%         'Sheet',    d.player.specific.lookup_table.sheet_number); 
    
    % Initialize the score_data subfield
    d.player.modcheck.score_data = struct(); 
    
    % Set initialized to true
    d.player.modcheck.initialized = true; 
    
    return
    
end % if ~d.player.modcheck

% Gather information we need to lookup scoring information
trial = d.sandbox.trial;
filename = d.sandbox.playback_list{trial};

% Digest filename into file parts. We'll use this to filter the table
% below.
[PATHSTR, NAME, EXT] = filepath(filename); 

% Filter the table to get trial-specific entry
filtered_table = filter_table(d.player.modcheck.table, 'track_name', NAME); 

% Put the words into a GUI friendly version (that is, a cell array)
key_words = cellstr(filtered_table.words{1}); 

% Call the scoring GUI
score_data = WordSpan_Scoring('words', key_words); 

% Stick the scoring data in the results structure
d.player.modcheck.score_data(trial) = score_data; 