function [playlist, lists, wavfiles] = SIN_getPlaylist(opts, varargin)
%% DESCRIPTION:
%
%   Function to return a playlist for a specific test. This is essentially
%   a wrapper for SIN_stiminfo, which returns directory and file
%   information.
%
% INPUT:
%
% SIN specific: 
%   
%   opts:   SIN options structure, which must contain the parameters listed
%           below in the "specific" field. Specific must contain the
%           'genPlaylist' subfield as well with the parameters listed below
%
% Parameters (in opts.specific.genPlaylist field ...)
%
%   'files':        cell array, a list of file names (must be full paths).
%                   If provided, then the function will use this as a file
%                   list rather than the output from SIN_stiminfo.
%
%   'NLists':   number of lists to concatenate for playbacklist. This
%               proved useful when administering tests that require more
%               than a single list (e.g., a 20 sentence HINT or the NAL
%               adaptive algorithm, which can use a large number of
%               sentences). 
%
%   'Randomize':    randomize playback list in various ways. This proved
%                   useful in instances when a true randomization is not
%                   appropriate (e.g., if stimuli in the first list must be
%                   completed before the stimuli in the second list are
%                   presented. (not implemented)
%
%                       '':     no randomization. 
%
%                       'lists':   Randomize list order. Note that stimuli
%                                  within each list are NOT randomized.
%
%                       'within':       Randomize each file order
%                                       independently for each list, then
%                                       concatenate (randomized) lists.
%
%                       'lists&within': a combination of 'lists' and
%                                       'within' randomization schemes
%                                       employed. So, list order is
%                                       randomized and stimuli within each
%                                       list is randomized as well.
%
%                       'full': concatenate all lists FIRST, then
%                               randomize.
%
%   'Repeats':  string, description of how to handle repeated lists
%
%           'never': do not allow lists to repeat (ever) across all tests.
%
%           'allbefore':    cycle through all available lists before
%                           repeating.
%           'any':  truly randomized list selection, with replacement upon
%                   each call
%
%   'UsedList':     string, path to a mat-file containing a list of which
%                   lists have been used. CWB imagines a different file for
%                   each participant. A single file should be used for all
%                   tests if the user wants to prevent list repeats in
%                   different tests (e.g., HINT (SNR-50) and HINT
%                   (NALadaptive), etc.). Test-specific files an also be
%                   used if the user just wants to prevent using the same
%                   list in the context of a specific test. 
%
%   'Append2UsedList':  bool, instructions on whether or not to append the
%                   selected lists to the 'used list' mat file. The
%                   appending should be handled by a second function that
%                   can be invoked independently (e.g., after test
%                   completion, for instance).
%
%                   Note: this is intended primarily for debugging
%                   purposes. Generally, CWB recommends setting this to
%                   false and managing the list in a smarter way elsewhere
%                   (e.g., in SIN_runTest)
%
% OUTPUT:
%
%   playlist:   cell array, each element is the path to a file to play.
%
%   lists:      cell array, equivalent of "list_dir" return from
%               SIN_stiminfo
%
%   wavfiles:   cell array, equivalent of "wavfiles" return from
%               SIN_stiminfo
%
% Development:
%
%   1. Allow user to input semicolor delimited randomization instructions.
%   This way, the user can combine randomization schemes and create new
%   functionality with less hassle. 
%
%   2. Note that randomization does not work properly for tests that do not
%   have lists in them. If it's just a sequence of WAV files, then the list
%   will be returned in the same order every time. Should work on this. 
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% SEED RANDOM NUMBER GENERATOR
rng('shuffle', 'twister');

%% GET PARAMETER LIST, PLACE IN STRUCTURE
%   Combine options structure and parameter list. This function relies on
%   the 'specific' subfield of opts.
d=varargin2struct(opts.specific.genPlaylist, varargin{:});  

%% INITIALIZE RETURN VARIABLES
playlist = {}; 

%% GET LIST INFORMATION FOR TEST
%   - call SIN_stiminfo
%   - if lists exist (list dir isn't empty), move forward. Otherwise, just
%   return the wavfiles (e.g., with ANL)
%   - Only call SIN_stiminfo if the user has not provided a specific file
%   list to use
if isfield(d, 'files') && ~isempty(d.files)
    % If the user provides a specific stimulus set to use, then use those
    % files. Otherwise, grab default information from SIN_stiminfo. 
    lists = {};
    wavfiles = d.files;
    
else
    [lists, wavfiles]=SIN_stiminfo(opts); 
end % if isfield ...

%% RETURN WAVFILES
%   We only need to do the following if we have lists to choose from.
%   If we don't (e.g., with ANL), then just return the wavfiles variable.
if isempty(lists) 
    playlist = wavfiles; 
%     return
end % if isempty(lists)

%% FIND THE NUMBER OF TIMES EACH LIST HAS BEEN USED
%   - This information is used below to generate a playlist. 
ntests = SIN_UsedListInfo(d.UsedList, 'task', {{'ntests'}}, 'lists', {lists}); 

% group lists by the number of tests each has been used in    
nunique = unique(ntests); % find the unique range of ntests.

%% GENERATE A LIST MASK 
%   - This will be based on the number of lists (NLists) and the
%   'Repeats' parameters.
listmask = false(numel(ntests), 1); % assume we can't use any lists be default

switch lower(d.Repeats)
    
    case 'never'
        
        % If we cannot repeat lists under any circumstances, then only
        % allow lists that have not been used
        listmask = find(ntests == 0); 
        
    case {'any'}
        
        % If we can repeat lists, then allow all lists through the mask
        listmask = 1:numel(lists); 
        
    case 'allbefore'
        
        % list mask is a sorting array to order the lists based on how many
        % times the tests have been repeated. 
        [~, listmask] = sort(ntests, 'ascend'); 
        
    otherwise
        
        % Throw an error if we encounter an unknown repeats parameter.
        error('Unknown Repeats parameter');         
        
end % switch

%% DO WE HAVE ENOUGH LISTS?
%   - If not, then throw an error. 
%   - Should only happen if the user requests more lists than are available
%   or if Repeats is set to 'never'. 
if d.NLists > numel(listmask)
    error('Not enough lists!');    
end % if d.NLists

%% APPLY MASK TO ntests
%   - ntests will be used below to shuffle lists
ntests = ntests(listmask); 

% Find the unique number of tests in ntests
nunique = unique(ntests);

%%  LIST ORDER
%   This randomization approach is not "truly" random. The randomization
%   approach differs based on the Repeats scheme above.
%       - For 'any', lists selection is truly randomized.
%       - 'allbefore', each cluster of lists (clustered based on how many
%       tests they have been usd in; so all lists with ntests==0 is a
%       cluster, ntest==1 is another cluster, etc.) is randomized. 
%       - 'never', the ntests == 0 cluster is randomized.
if ~isempty(strfind(d.Randomize, 'lists'))
    
    switch lower(d.Repeats)
        
        case {'any', 'never'}
            % Shuffle the whole list
            listmask = randperm(numel(listmask)); 
            
        case 'allbefore'           
            
            % Shuffle each cluster
            for i=1:numel(nunique)
                
                % Cluster-level logical mask
                mask = ntests == nunique(i);
                
                % Temporary (smaller) listmask. Easier to work with
                tlistmask = listmask(mask); 
                
                % Randomize
                tlistmask = tlistmask(randperm(numel(tlistmask))); 
                
                % Reassign (shuffled) data to larger array
                listmask(mask) = tlistmask; 
            end % 
            
        otherwise
            error('Some issue with randomization'); 
            
    end % switch
    
end % if ~isempty(strmatch ...
    
%% SELECT LISTS TO USE
lists2use = listmask(1:d.NLists);

%% CONSTRUCT PLAYLIST
%   - Append the correct file names to the play list
%   - Also, if the user wants stimuli shuffled "within" list, then shuffle
%   before appending the playlist
for i=1:numel(lists2use)
    
    % Grab the appropriate wavfiles
    tpl = wavfiles{lists2use(i)}; 
    
    % Randomize individual playlists if necessary
    if ~isempty(strfind(d.Randomize, 'within'))
        tpl = tpl(randperm(numel(tpl))); 
    end % if ~isempty
    
    % Append to playlist
    playlist = [playlist; tpl];
    
end % for i=1:numel...

%% FULL RANDOMIZATION
%   If users want a fully randomized playlist (CWB discourages this in most
%   contexts, particularly with "balanced" lists), then shuffle the whole
%   playlist.
if ~isempty(strfind(d.Randomize, 'full'))
    playlist = playlist(randperm(numel(playlist))); 
end % playlist 

%% APPEND STIMULUS LIST TO USED LIST
%   - If the user requests, we can add the compiled list to the "UsedList"
%   mat file.
%   - This is really only intended for debugging purposes. Not recommended.
if d.Append2UsedList
    SIN_UsedListInfo(d.UsedList, 'task', {{'add'}}, 'lists', {lists(lists2use)}, 'testID', opts.specific.testID);
end % if d.Append2UsedList