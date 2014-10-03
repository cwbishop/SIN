function [algo_handle, algo_index] = HINT_chooseAlgo(algos, startalgoat, trial, varargin)
%% DESCRIPTION:
%
%   Function to select the current algorithm being used for spech in noise
%   testing (e.g., HINT, MLST) on a given trial.
%
% INPUT:
%
%   algos:  cell array containing function handle to algorithms.
%
%   startalgoat:  integer array, which trial to start using each algo at. 
%                 Must have the same number of elements as algos.
%
%   trial:  integer, trial number.
%
% OUTPUT:
%
%   algo_handle:  function handle to algorithm to use on the specified trial.
%
%   algo_index:    integer, index of the algorithm selected.
%
% Christopher W Bishop
%   University of Washington
%   9/14

% Which algo should we be using?
algo_index = find(trial>=startalgoat, 1, 'last');
algo_handle = algos{algo_index};