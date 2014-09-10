function bscore = HINT_score2binary(score, varargin)
%% DESCRIPTION:
%
%   Function to convert scoring arrays to a binary outcome for use with
%   HINT and other similar tests.
%
%   This is designed to work specifically with the scoring matrix generated
%   by modcheck_HINT_GUI, but should be adaptable to other circumstances
%   without too much trouble.
%
% INPUT:
%
%   score:  cell array, each cell contains an integer array of scoring
%           information. Here is the integer key
%
%               1:  a scored correct response
%               2:  a scored incorrect response
%               -1:  unscored word
% OUTPUT:
%
%   bscore: a binary scoring of length T, where T is the number of trials.
%           Trial value will be 1 if all scored items were correct. Trial
%           value will be set to 0 if any scored items are missed. In
%           otherwords, this converts scoring information into an 'all or
%           nothing' scenario.
%
%           Note: if no scored items are found, the binary outcome will be
%           0 (incorrect). Could make an argument to go either way ...
%
% Development:
%   
%   1. Generalize function to work with generic rule sets. 
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% INTITIALIZE RETURN VARIABLE
%   Intialize all trials as "incorrect" by default
bscore = false(numel(score),1);

%% LOOP THROUGH TRIAL INFORMATION, DETERMINE TRIAL OUTCOME
for i=1:numel(score)
    
    % Create a mask for scored items
    mask = score{i}~=-1; 
    
    % If there aren't any scored items in the trial, then continue to the
    % next loop interation. This means the trial is scored as a '0' (the
    % default). 
    if ~any(mask) 
        continue 
    end % if ~any(mask)
        
    % If any scored items are incorrect (i.e., not 1), then accept the
    % default trial state ('0').
    if ~all(score{i}(mask)==1)
        continue
    end 
    
    % If we get through the two checks above, then we can assume we have a
    % correct trial, set to bit to true
    bscore(i) = true; 
    
end % for i=1:numel(score)