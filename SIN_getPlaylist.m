function [playlist, lists, wavfiles] = SIN_getPlaylist(opts, varargin)
%% DESCRIPTION:
%
%   Function to return a playlist for a specific test. This is essentially
%   a wrapper for SIN_stiminfo, which returns directory and file
%   information.
%
%   CWB hopes to expand this function to also do the following
%
%       1. In tests like HINT and MLST, track which lists have been
%       presented to a specific subject. Users can then specify whether or
%       not they will allow playlists to repeat; this can proceed ine
%       several ways:
%
%           A) minimize repeats: don't repeat lists until all available
%           lists have been played
%
%           B) no repeats: throw a shoe if we run out of lists to present
%
%           C) no constraints: repeat lists at will (fully randomized list
%           selection)
%
% INPUT:
%
%   The input can take one of several forms. 
%
% SIN specific: 
%   
%   opts:   SIN options structure, which must contain the parameters listed
%           below in the "specific" field. 
%
% Parameters (for SIN_stiminfo):
%
%   - All parameters necessary to call SIN_stiminfo (see SIN_stiminfo for
%   details; this can vary by test)
%
% Parameters (for SIN_getPlaylist)
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
%                       'lists':   Randomize list order. Note that stimuli
%                                  within each list are NOT randomized.
%
%                       'within':       Randomize each list order
%                                       independently of other lists, then
%                                       concatenate lists.
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
%                   (NALadaptive), etc.). 
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
%
% Development:
%
%   1. Allow user to input semicolor delimited randomization instructions.
%   This way, the user can combine randomization schemes and create new
%   functionality with less hassle. 
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
[lists, wavfiles]=SIN_stiminfo(opts); 

%% RETURN WAVFILES
%   We only need to do the following if we have lists to choose from.
%   If we don't (e.g., with ANL), then just return the wavfiles variable.
if isempty(lists) 
    playlist = wavfiles; 
    return
end % if isempty(lists)

%% SORT LISTS BY NUMBER OF TESTS 
%   - Sort lists by the number of tests each has been used in.
%   - Can only do this if the user gives us UsedList information
% if isfield(d, 'UsedList') && ~isempty(d.UsedList)
    
% Which of these lists have been presented previously?
%   - returns 0 if unused, and a positive integer if it has been used.
%   For more details, see help SIN_UsedListInfo.
%     isused = SIN_UsedListInfo(d.UsedList, 'task', {{'isused'}}, 'lists', {lists});

% Find the UsedLists with the minimum number of repeats; that is,
% the lists that have been used in the fewest tests. 
%   - Can get number of tests using 'ntests' method of
%   SIN_UsedListInfo
ntests = SIN_UsedListInfo(d.UsedList, 'task', {{'ntests'}}, 'lists', {lists}); 

% group lists by the number of tests each has been used in    
nunique = unique(ntests); % find the unique range of ntests.

%% RANDOMIZE LIST ORDER
%   - We want to randomize list order BEFORE we apply a list mask 
%   XXX need to write this XXX

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

%% RANDOMIZE LIST ORDER
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