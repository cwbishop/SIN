function [mod_code, d]=modcheck_HINT_GUI(varargin)
%% DESCRIPTION:
%
%   Function to handle HINT scoring via the HINT GUI. When paired with
%   portaudio_adaptiveplay and a suitable modifier, this can be used to
%   administer the HINT. 
%
% INPUT:
%
% Parameters (set by portaudio_adaptiveplay)
%
%   'playback_list':    cell array, sentences being presented in
%                       portaudio_adaptiveplay.m. Sentence order should
%                       match that in portaudio_adaptiveplay. 
%
%                       Note: This field (should) be automatically set by
%                       portaudio_adaptive play. That is, the user
%                       typically does not need to specify this. 
%
%   'data_channels':     XXX
%
%   'physical_channels': XXX
%
%           XXX Needs data/physical_channels for plotting purposes. This
%           should correspond to the data being tracked/adapted. XXX
%
%   The following parameters are set in SIN_TestSetup.m 
%
%   'scoring_labels':   two element cell array containing a text label for
%                       the first ("correct") and second ("incorrect")
%                       radiobutton option. (e.g., {'Correct',
%                       'Incorrect'}).
%
%   'scored_items':   string, type of scoring approach to use. This can
%                       be expanded easily to incorporate new scoring
%                       schemes.
%
%                           'allwords':   each word has an equal score
%                                           associated with it. 
%
%                           'keywords':    Only keywords (capitalized)
%                                          are scored.
%
%                           'sentences':   A binary scoring scheme with one
%                                          scored "unit" per sentence. This
%                                          approach is applicable for the
%                                          PPT. 
%
%   'algo': cell array, each element is a function handle pointing to an 
%           algorithm (e.g., algo_HINT1up1down, algo_HINT3down1up, etc.).
%           These functions must interpret the data in a meaningful way and
%           return a compatible mod_code to this modcheck for further use. 
%
%   'startalgoat': integer vector, specifies the first trial overwhich the
%                   corresponding algorithm should be applied.
%                       
% OUTPUT:
%
%   'mod_code':     modification code. The returned modification code
%                   depends on the algorithm implemented. 
%                       0:  no modification necessary.
%                       -1: make target quieter
%                       1:  make target louder
%
%                   NOTE: The algorithmic helper functions provided by the
%                   user must supply the correct codes. There's no check in
%                   place to make sure we're getting the correct codes
%                   back. 
%
%   d:  updated data structure used by portaudio_adaptiveplay.m
%
% Development:
%
%   Complete (so far) 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% INPUT CHECK AND DEFAULTS

% initialize mod_code to zero (do nothing) 
mod_code=0;

%% INPUT ARGS TO STRUCTURE
d=varargin2struct(varargin{:});

if ~isfield(d, 'player')
    d.player=d; 
end % opts

% Grab important variables from sandbox
%   Sandbox is a "scratch pad" of sorts that allows the user to share
%   variables between the player, modchecks, and modifiers. CWB originally
%   used globals to do this, but globals are scary and very difficult to
%   control. Debugging can also be a pain since a variable can be changed
%   in a totally unrelated function to the error being generated.
trial = d.sandbox.trial;

%% IMPORT SENTENCES FROM FILE
%   This should only be run during initialization. 
%       - Read in sentence information from xlsx file. 
%       - Very slow step, so keep calls to a minimum. 
if ~isfield(d.player.modcheck, 'sentence') || isempty(d.player.modcheck.sentence)
    
    % Clear the NAL adaptive algorithm's persistent variables
    %   If we don't do this, the algo will pick up where it last left off.
    %   We don't want that. 
    if isequal(d.player.modcheck.algo, 'NALadaptive');
        clear algo_NALadaptive; % clear the algo
        [d.sandbox.NAL] = algo_NALadaptive('initialize', ...
            d.player.modcheck.algoParams); % initialize algorithm and NAL structure 
                                  % user defined parameters. 
    end % if isequal
    
    % Grab sentence information
    %   This initial step will update the 'modcheck' field by adding in
    %   HINT list information from an XLS spreadsheet.
    d=importHINT(d); 
    
    %% Initialize other fields
    
    % Plotting information for HINT_GUI
    %   Initialize other fields that are important later. 
%     d.sandbox.xdata=1; % first trial
%     d.sandbox.ydata=0; % no changes applied
    d.player.modcheck.xlabel='Trial #';
    d.player.modcheck.ylabel='SNR (dB)'; 
    d.player.modcheck.ntrials=length(d.sandbox.playback_list); % number of trials (sets axes later)
    d.player.modcheck.score = {};
    d.player.modcheck.nconsecutive = 0; % initialize # of consecutively correct trials. Used for 3down1up algo and potentially others.
%     d.modcheck.score_labels={'Correct', 'Incorrect'}; % This is set in SIN_defaults

    % Scoring information
    %   Use dynamic field names 
    for i=1:length(d.player.modcheck.score_labels)
        d.player.modcheck.(d.player.modcheck.score_labels{i})=0;        
    end % for i=1:length ...
    
    % After we initialize, return control to invoking function
    %   This way we don't bring up the scoring GUI until after the first
    %   sentence is complete. 
    return; 
    
end % if ~isfield p ...

% FIND SENTENCE FOR SCORING
%   finds information for the sentence to be sored.
fname=d.sandbox.playback_list{trial}; 

% Get file parts
[PATHSTR,NAME,EXT] = fileparts(fname);

% Just need the List and file information. 
%   - Find where the list information starts, then truncate to look just
%   for the 01/03/02, etc. of the file. Then append a .wav to it. This
%   approach is kind of silly, CWB admits, but it allows the user to use
%   files with different suffixes without too much trouble. 
[start, stop] = regexp(fname, d.specific.list_regexp);
% fname=[fname(start:stop+1) NAME EXT]; 
fname = [fname(start:stop+1) NAME]; % don't match file extensions, just use the root of the name

% Find sentence information by matching the filepath between. 
%   Don't reassign 'd' return, since this will be updated in stupid ways on
%   account of the additional search parameters. Essentially there will be
%   an added 'filepath' field that will be very confusing. In comparison,
%   the 'o' structure should contain just the information we're looking
%   for. 
[~, o]=importHINT(d, 'filepath', fname); 

%% DETERMINE SCORING VECTOR
%   Scoring vector will change depending on the 'scoring_method' parameter.
%   The various methods require some or all words to be scored. This
%   section of code determines the scoring vector, which is then used to
%   change the GUI below.
%
%   See help for a conceptual description of each of these scoring methods
[iskey, words] = SIN_keywords(o.sentence{1}); 
isscored = false(numel(words)); % initalize scoring to false.

%% DETERMINE WHICH ITEMS ARE SCORED
%   Each scoring method has slightly different characteristics. These
%   options can be expanded to incorporate nearly any scoring scheme. 
switch d.player.modcheck.scored_items
    
    case {'allwords'}
        % All words are scored, but the # of correct is based on the number
        % of correct words. 
        %
        % OR
        %
        % All words are scored, but only 100% correct responses counts as
        % correct.        
        
        % Score all words
        isscored=true(numel(words)); 
        
    case {'keywords'}
        
        % Get a logical vector from SIN_keywords
        isscored = iskey;
        
    case {'sentences'}
        
        % This scoring method was originally written to support
        % administering the PPT, so it is described within that context
        % below. But this can be used to adminster other tests as well.
        %
        % In PPT, the listener responds with a subject impression of
        % whether or not he/she understood 100% or not 100% of all words in
        % the sentence. 
        %
        % To score this, the experimenter just needs an "all or nothing"
        % scoring scheme. So, we give only a single radio button selection
        % and mark the remaining words as "unscored" (-1). 
        isscored(1) = true; 
        
    otherwise
        
        error('Unknown scoring method'); 
        
end % switch/otherwise

%% CALL SCORING GUI
%   Pulls up a scoring GUI designed by CWB in GUIDE + lots of other manual
%   customizations. 
[fhand, score]=HINT_GUI(...
    'title', ['HINT: ' o.id{1} ' (' num2str(numel(isscored(isscored))) ' possible)'], ...
    'words', {words}, ...
    'xdata',  1:d.sandbox.trial, ...
    'ydata',  db(squeeze(d.sandbox.mod_mixer(d.player.modcheck.data_channels, d.player.modcheck.physical_channels, :))), ... % plot the mod_mixer history. This tells us precisely the scaling factor applied to our stimuli. 
    'xlabel', d.player.modcheck.xlabel, ...
    'ylabel', d.player.modcheck.ylabel, ...
    'ntrials', d.player.modcheck.ntrials, ...
    'score_labels', {d.player.modcheck.score_labels}, ...
    'isscored', isscored); 

% Copy figure handle over to d structure.
d.player.modcheck.handles=guidata(fhand); 

% Get all handles
h=guidata(fhand);

% Assign axis handle back to a more central location (so other functions
% can plot if necessary).
d.sandbox.axes=h.panel_plot; 
d.sandbox.figure=h.figure1; 

% Append scoring information to modcheck
%   Useful for algorithm tracking later. 
d.player.modcheck.score{trial} = score; 

% Also append to 'o' structure and save it all together
o.score = score; 

% Append sentence information to structure as well
d.player.modcheck.trial_info{trial} = o; % save over sentence information. All of it. 

% Error check for debugging
if numel(d.player.modcheck.score) ~= numel(d.player.modcheck.trial_info)
    error('Something not making sense'); 
end % if ...

%% CHOOSE CORRECT ALGO
%   In special cases, it may be necessary to combine algorithms for testing
%   purposes (e.g., 1up1down for N trials, followed by 4down1up). This can
%   be done using this algo selection criteria.
[algo, algo_index] = HINT_chooseAlgo(d.player.modcheck.algo, d.player.modcheck.startalgoat, trial); 

%% APPLY ALGORITHM
%   Get a mod_code back from the algorithm after passing it in the scoring
%   history. 
%
%   Note: we only want the algorithm making decisions based on the trials
%   controlled by that specific algorithm. So, crop score to only include
%   the values that should be considered by the algorithm.
mod_code = algo({d.player.modcheck.score{d.player.modcheck.startalgoat(algo_index):end}}); 

%% CLOSE GUI
%   Only close it down if we're done. We are "done" if:
%       - All trials have been presented
%       - The player state has been set to exit (player will not present
%       anymore stimuli). 
if trial==length(d.sandbox.playback_list) || isequal(d.player.state, 'exit')
    close(d.sandbox.figure);
end % if trial== ...