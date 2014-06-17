function [NAL_OUT] = algo_NALadaptive(score, varargin)
%% DESCRIPTION:
%
%   Function to use an adaptive algorithm to control signal level (or
%   SNR). 
%
%   The algorithm is divided into three phases (Phases 1 - 3). The phases
%   differ based on decibel step size and termination criteria. Below is a
%   short summary of this information. CWB encourages the user to *read the
%   paper* to double check things.
%
%   Phase 1: (5 dB steps)
%       - Minimum of 4 sentences
%       - Minimum of one reversal
%
%   Phase 2: (2 dB steps)
%       - Minimum of 4 MORE (minimum of 8 total) sentences.
%       - (corrected) Standard Error (cSE) no greater than 1 dB. 
%       - Note that cSE estimates are based on Phase 2 sentences only
%
%   Phase 3: (1 dB steps)
%       - At least N sentences during Phases 2/3.
%       - cSE < 0.8 dB. 
%       - Note that cSE estimates are based on Phases 2 and 3 only.
%       - Note that "N" defaults to 16 in the NAL program   
%
% INPUT:
%   
%   score:  bool array, each element corresponds to a scorable unit (e.g.,
%           phoneme, morpheme, word, etc.). True if the scorable unit is
%           "correct". False if the scorable unit is "incorrect". 
%
% Parameter list:
%
%   'target':   target percentage correct.
%
%   'correction_factor': double, correction factor to apply to SE
%                        calculations. (see Table 1 of Keidser (2013))
%
%   'min_trials':   minumum number of trials to complete during phases 2
%                   and 3.
%
% OUTPUT:
%
%   NAL_OUT:    NAL data structure with the following fields
%
%                   'target':   the target percentage (user defined)
%
%                   'correction_factor':    correction factor applied in
%                                           standard error calcuations.
%
%                   'min_trials': the minimum number of trials needed in
%                                 phases 2/3 before the algo will terminate
%
%                   'dBstep': 1xT array, each element corresponds to the
%                             decibel change to apply to the next trial.
%                             So, if dBstep=[5 5 5], then the 4th trial
%                             will have a 15 dB net gain applied to it. T
%                             is the number of trials
%
%                   'dBnow': the cumulative dBstep for the most recent
%                            trial. If dBnow=[0 5 10], then the second
%                            trial was presented at +5 dB relative to its
%                            default volume level.
%
%                   'scoring_history': T element cell array, where T is the
%                                      number of trials. Each cell contains
%                                      the scoring information for the
%                                      corresponding trial provided by the
%                                      user.
%
%                   'phase': T element array, describes the testing phase
%                            of the most recent trial. Phases range from 1
%                            -4; 4 indicates the end of algorithm.
%
%                   'isreversal': T element array, true if the current
%                                 trial is a reversal?
%
%                   'trial_percentage': T element array, the % correct for
%                                       the corresponding trial
%
%                   'state': string, state of the algo.
%                       'run': it's running
%                       'finished': it's finished.
%
% References:
%
%   1. Keidser, G., et al. (2013). Int J Audiol 52(11): 795-800.
%
% Development:
%
%   1. Phase information is offset by a single trial, I think. Needs more
%   testing and more thinking by CWB. 
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% INPUT ARGS TO STRUCTURE
% d=varargin2struct(varargin{:});

%% DECLARE PERSISTENT VARIABLES
%   Create persistent structure 
persistent NAL;

% Set NAL to structure. Only done during initialization... need to make
% this smarter. 
%
% Also accommodates an initialization argument so users can reset the algo
% manually (recommended). 
if ~isstruct(NAL)
    
    NAL=varargin2struct(varargin{:});  
    
    % Add default fields
    flds = {'dBstep', 'dBnow', 'scoring_history', 'phase', 'isreversal', 'trial_percentage', 'state'};
    for i=1:numel(flds)
        if ~isfield(NAL, flds{i})
            NAL.(flds{i}) = [];
        end % if ~isfield
    end % for i=1:numel(flds)
    
    % Set algorithm state to 'run'
    if isempty(NAL.state)
        NAL.state = 'run'; 
    end 
    
    NAL.scoring_history = {}; % need this to be a cell array
    
    % Set dBnow
    %   dBnow tracks the cumulative scaling over all trials. So this will
    %   be the equivalent of the sum of dBstep(1:end-1) typically. First
    %   trial has a level (or SNR) of 0 by default. The applied changes are
    %   all relative, so we can call the first point whatever we want. 0 is
    %   easier to think about. 
    if isempty(NAL.dBnow)
        NAL.dBnow=0;
    end % if isempty(NAL.dBnow);    
    
end % if ~isstruct

% Allow for query or initialization return
%   If user calls algo with no input arguments, then just return the NAL
%   structure
if (~exist('score', 'var') && nargin==0) || isequal(lower(score), 'initialize')
    NAL_OUT=NAL; 
    return;
end % if ~exist('score' ...

% Assign correct dimensions to score
t.fs=0; 
score = SIN_loaddata(score, t);

% Assign current phase. 
%   The checks below determine if we are about to enter the next phase. 
NAL.phase(end+1) = getNALphase(NAL); 

% Refresh dBnow
if ~isempty(NAL.dBstep)
    NAL.dBnow(end+1) = NAL.dBnow(end) + NAL.dBstep(end); 
end 

% Append score
NAL.scoring_history{end+1} = score; 

% Score trial
NAL.trial_percentage(end+1) = numel(score(score))/numel(score)*100;

% Which direction is the next step in?
NAL.dBstep(end+1) = stepSign(NAL); % this just gives us the SIGN, not the step SIZE

% Is this a reversal?
%   Compare signs of last two elements of dBstep. If the signs are
%   different, then it's a reversal. If they are the same, then it is NOT a
%   reversal. 
NAL.isreversal(end+1) = isReversal(NAL); 

% Which phase is the next trial?
% What's the step size (dB) for the upcoming trial?
[tphase, tdBstep] = getNALphase(NAL); 

if ~isempty(tdBstep)
    NAL.dBstep(end) = NAL.dBstep(end).*tdBstep; % multiply sign by dBstep size
end 

% Termination phase
%   getNALphase will return 4 if the algorithm has finished
if tphase == 4
    NAL.state = 'finished'; 
end % if tphase ...

% dBnext:
%   The decibel scaling factor to apply to the upcoming stimulus
NAL.dBnext = NAL.dBnow(end) + NAL.dBstep(end); 
dBnext = NAL.dBnext; 

% Assign return variables
NAL_OUT = NAL; 

function isRev = isReversal(NAL)
%% DESCRIPTION:
%
%   Function to determine if we just encountered a reversal

% NOTE: dBstep might be 0. Need to not count this as a reversal

% Get sign of steps
tdBstep = sign(NAL.dBstep(NAL.dBstep~=0)); 

if numel(tdBstep) < 2
    % Can't have a reversal with fewer than 2 (signed) changes. Zero
    % doesn't contribute.
    isRev = false; 
    return;
else
    
    tdBstep = tdBstep(end-1:end); 
    
end % if numel(NAL.dBstep) ...

if diff(tdBstep) == 0
    % No reversal if the most recent directional changes are the same
    isRev = false;
elseif diff(tdBstep)~=0
    % It's a reversal if the most recent (signed) Changes do not match. 
    isRev = true;
end % if diff(tdBstep)

function [o]=cSE(NAL)
%% DESCRIPTION:
%
%   Function to calculate corrected SEM from phases 2 and 3. 

% Convert dBstep into cummulative levels
%   First trial is our "zero" point. All subsequent trials are changed
%   relative to zero.
%
%   Recall that dBstep is of the NEXT trial, so we have to shift the array.
%   The last entry hasn't been presented yet, so clip it. 
% dBstep = [0 NAL.dBstep(1:end-1)]; 

% Initialize dB sum array
dBsum=NAL.dBnow; 

% Convert dBstep to cumulative levels
% for i=1:length(dBstep)
%     dBsum(i) = sum(dBstep(1:i));
% end % for i=1:length(dBstep)

% Get phase mask
mask = NAL.phase == 2 | NAL.phase == 3;

% Get temporary data
dBsum = dBsum(mask); 

% Calculate cSE
o = NAL.correction_factor * sem(dBsum); 

function [phase, dBstep] = getNALphase(NAL)
%% DESCRIPTION:
%
%   Function to determine which phase of the algorithm we are in, as well
%   as the step size associated with each phase.
%
%       Phase 1: 5 dB
%       Phase 2: 2 dB
%       Phase 3: 1 dB

% Assume we're starting at phase one
phase = 1; 
dBstep = 5; % 5 dB step size

persistent isphase2 isphase3 isphase4;

if isempty(isphase2), isphase2=false; end
if isempty(isphase3), isphase3=false; end
if isempty(isphase4), isphase4=false; end 

% Set phase
if isphase4
    phase=4; 
elseif isphase3
    phase=3;
elseif isphase2
    phase=2;
end % if isphase4 ...
    
% Get the number of reversals
%   Pass dBstep information, which tells us the history of the step sizes. 
nrevs = numel(find(NAL.isreversal));

% Get (corrected) standard error for each phase
% display(cSE(NAL)); % for debuggin'

% Get phase
%   Note that the PHASE refers to the phase of the most recently presented
%   trial. 
%
%   In contrast, dBstep refers to the step for the NEXT trial. So we have
%   to handle the checks independently. 
if (numel(NAL.phase(NAL.phase == 2 | NAL.phase ==3 ) )  >= NAL.min_trials ) ...
        && cSE(NAL) < 0.8 && isphase3
    isphase4 = true;  % phase 4 means we stop.
    dBstep=[]; 
elseif numel(NAL.phase)>= numel(NAL.phase(NAL.phase==1)) + 4 && cSE(NAL) <= 1 && isphase2
    isphase3 = true; 
    dBstep = 1; 
elseif numel(NAL.phase) >= 4 && nrevs > 0 % XXX Reversal check    
    isphase2 = true; 
    dBstep = 2; 
end % 

function [s] = stepSign(NAL)
%% DESCRIPTION:
%
%   Function to determine the sign of dBstep for upcoming trial

if NAL.trial_percentage(end) < NAL.target
    s = 1; % make sounds louder
elseif NAL.trial_percentage(end) > NAL.target
    s = -1; % make sounds quieter
elseif NAL.trial_percentage(end) == NAL.target
    s = 0; % don't change the sound level
else 
    % This should theoretically never happen, but CWB wants to be careful. 
    error('No idea what to do here');
end % if NAL_trial_percentage ...