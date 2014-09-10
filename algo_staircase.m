function D=algo_staircase(score, varargin)
%% DESRIPTION:
%
%   This is the core control for all stair case algorithms (e.g., 1up1down,
%   4down1up, etc.) in the SIN package. In order to remain flexible, it
%   uses a "decision matrix" (see below) to provide instructions on what
%   should be done on the next trial. 
%
%   Although this function controls the key decision making portions of
%   staircase algorithms, it does *not* invoke any changed directly.
%   Rather, it provides a general set of instructions through the decision
%   matrix that can be interpreted in other functions.
%
% INPUT:
%
%   score:  Nx1 array, where N is the number of trials up to the current
%           decision point (e.g., [1 0 0 1 0]).
%
% Parameters:
%
%   'decision_matrix':  a 3xY matrix, where Y is the number of decision
%                       criteria the function should consider. Each row
%                       contains a unique piece of information that
%                       provides the information the algo needs to make a
%                       decision and provide meaningful feedback.
%
%                           row 1:  the value to look for in the score
%                                   array
%
%                           row 2:  the number of *consecutive* instances
%                                   of row 1's value that must be
%                                   encountered before the decision
%                                   criterion is satisfied.
%
%                           row 3:  the return value when a decision
%                                   criterion is met.
%
%   'default':  integer, default return value if none of the criteria are
%               met
%
% OUTPUT:
%
%   D:  decision value from row 3 of decision matrix of the *first*
%       satisfied criterion in the decision_matrix. 
%
%       Note that if several decisions are met, the algorithm will only
%       return the decision for the first satisfied criterion.
%
% Development:
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

%% SET DEFAULT VALUE 
D = d.default; 

%% FIND LENGTH OF REPEATS FROM END WORKING BACKWARDS
val = score(end); % the last entry into score
if any(score~=val)
    % This will only work if we have a value that differs from val
    nconsec = numel(score) - find(score~=val, 1, 'last');
else
    nconsec = numel(score);
end % if any

%% FIND CRITERIA THAT MATCH
%   We only want criteria that have the specified value AND can be divided
%   evenly into the number of consecutive trials val has been observed. 
%
%   The latter is necessary to "reset" the algorithm after the number of
%   consecutive instances has been reached once (or more) times. (e.g.,
%   with [1 1 1 1 1] and a 4up1down algo, we would otherwise increment
%   after trial 4 and 5. This way we only increment after trial 4). 
decmask = d.decision_matrix(1,:) == val & mod(nconsec, d.decision_matrix(2,:))==0;
decmat = d.decision_matrix(:, decmask); 

%% NOW WHAT TO DO?
if size(decmat, 2)>1
    error('Multiple matching criteria. Dunno what to do.');
elseif size(decmat, 2)==1
    D = decmat(3,1); 
    return
end % if nume(decind)>1