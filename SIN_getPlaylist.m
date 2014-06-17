function SIN_getPlaylist(varargin)
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
%           below in the "specific" field
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
%           'none': do not allow lists to repeat (ever) across all tests.
%
%           'allbefore':    cycle through all available lists before
%                           repeating.
%           'any':  truly randomized list selection, with replacement upon
%                   each call
%
%   'UsedListMat':  string, path to a mat-file containing a list of which
%                   lists have been used. CWB imagines a different file for
%                   each participant. A single file should be used for all
%                   tests if the user wants to prevent list repeats in
%                   different tests (e.g., HINT (SNR-50) and HINT
%                   (NALadaptive), etc.). 
%
%   'Append2List':  bool, instructions on whether or not to append the
%                   selected lists to the 'used list' mat file. The
%                   appending should be handled by a second function that
%                   can be invoked independently (e.g., after test
%                   completion, for instance).
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

%% GET PARAMETER LIST, PLACE IN STRUCTURE
d=varargin2struct(varargin{:});  

%% GET LIST INFORMATION FOR TEST
%   - call SIN_stiminfo
%   - if lists exist (list dir isn't empty), move forward. Otherwise, just
%   return the wavfiles (e.g., with ANL)

%% REMOVE USED LISTS
%
%   - Load the UsedListMat file and check to see which lists have been used
%   previously.
%   - Those that have been used previously should be removed from the
%   available list before moving on.

%% 

%% RANDOMIZE LIST SELECTION
%   - Either concatenate stimuli across lists, then 