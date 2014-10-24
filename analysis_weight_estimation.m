function [weights] = analysis_weight_estimation(results, varargin)
%% DESCRIPTION:
%
%   This function uses a series of recordings to estimate the location and
%   channel specific weights that can be applied to adjust theoretical
%   level estimates in a multi-speaker/channel setup.
%
%   This was originally written as an auxiliary test/analysis to support
%   the primary Hagerman analysis, but can likely be used in many recording
%   circumstances, particularly when the target and masker are presented
%   from a different combination of speakers.
%
%   Weights are estimated using relative RMS estimates.
%
% INPUT:
%
%   results:    results structure from SIN's player_main
%
% Parameters:
%
%   reference_location: double, indicates which speaker number should be
%                       used as the reference location (i.e., which
%                       location's weight should be defined as 1 for a
%                       given channel). In the context of Hagerman style
%                       recordings, this will likely need to be the
%                       location of the target track (e.g., 1 for SNR
%                       grant). 
%
% OUTPUT:
%
%   weights:    a speaker x channel weighting matrix.
%
% Development:
%
%   1) reference_location should be generalized to accept a reference
%   matrix instead, CWB thinks ... but he can't wrap his head around it at
%   the moment, so went with the simpler solution. 
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% GET RECORDED DATA
%   Grab recorded data from each speaker/channel as well as the sampling
%   rate. 
for i=1:numel(results)
    recs{i} = results(i).RunTime.sandbox.mic_recording; 
end % for i=1:numel(results)

%% FIND RMS FOR EACH LOCATION/CHANNEL COMBINATION

% weights will store the rms estimation for each location/channel
% combination
weights = cell2mat(cellfun(@rms, concatenate_lists(recs), 'UniformOutput', false)); 

% Normalize to the reference location
weights = weights./(ones(size(weights,1), 1)*weights(d.reference_location,:));