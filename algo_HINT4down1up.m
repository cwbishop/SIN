function mod_code = algo_HINT4down1up(score, varargin)
%% DESCRIPTION:
%
%   Function to generate 4down1up algorithm behavior for Hearing in
%   Noise Test (HINT). This is essentially a wrapper for algo_staircase,
%   which makes the actual decisions. algo_HINT4down1up just massages the
%   'score' returned by modcheck_HINT_GUI into an appropriate format and
%   creates a (hard-coded) decision matrix for use with algo_staircase.
%
% INPUT:
%
%   score:  cell array of trial scores, as returned in modcheck_HINT_GUI.
%
% Paramters:
%
%   None (yet).
%
% OUTPUT:
%
%   mod_code:   modification code for use with SIN testing. 
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

%% CONVERT SCORE TO USABLE FORMAT
%   Convert score to a binary outcome usable by the staircase algorithm. 
bscore = HINT_score2binary(score); 

%% NOW CALL STAIRCASE ALGO
mod_code = algo_staircase(bscore, 'decision_matrix', [[true;4;-1] [false;1;1]], 'default', 0); 