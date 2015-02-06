function [weights_norm, weights] = analysis_weight_estimation(results, varargin)
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
%  Filter settings:
%
%   'apply_filter': bool, if true, then the filter with the following
%                   specifications is designed and applied to the
%                   recordings prior to any further calculations. This
%                   proved useful at UofI which had a tremendous amount of
%                   low-frequency drift. 
%
%                   Note that the fulter is designed using MATLAB's
%                   'butter' function combined with 'filtfilt'. Thus, the
%                   practical order of the filter is double what is
%                   specified below. User should adjust if necessary. 
%
%   'filter_type':  filter type, see butter for details (e.g., 'high')
%
%   'filter_order': filter order, see butter for details (e.g., 4)
%
%   'filter_frequency_range':   corner frequency information for filter design.
%                           This may be a one- or two-element vector
%                           depending on filter_type. See butter for
%                           details (e.g., 125).
%
% OUTPUT:
%
%   weights_norm:   a speaker x channel normalized weighting matrix. These
%                   are RMS measures normalized to the reference_location. 
%
%   weights:    same as weights_norm, except not normalized to
%               reference_location. It proved useful in some circumstances
%               to have a speaker and ear-specific estimate of RMS. That's
%               what this is. 
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

%% GET SAMPLING RATE
FS = results(1).RunTime.sandbox.record_fs;

%% GET RECORDED DATA
%   Grab recorded data from each speaker/channel as well as the sampling
%   rate. 
for i=1:numel(results)
    recs{i} = results(i).RunTime.sandbox.mic_recording;     
end % for i=1:numel(results)

% Are we applying a filter to our data?
if d.apply_filter

    % Note that frequency vector is normalized to Nyquist
    [b, a] = butter(d.filter_order, d.filter_frequency_range./(FS/2), d.filter_type);

    for i=1:numel(recs)
        for n=1:numel(recs{i})
            recs{i}{n} = filtfilt(b, a, recs{i}{n});         
        end % for n=1:numel(recs{i})
    end % for i=1:numel(recs)
    
end % d.apply_filter
%% FIND RMS FOR EACH LOCATION/CHANNEL COMBINATION

% weights will store the rms estimation for each location/channel
% combination
weights = cell2mat(cellfun(@rms, concatenate_lists(recs), 'UniformOutput', false)); 

% Normalize to the reference location
weights_norm = weights./(ones(size(weights,1), 1)*weights(d.reference_location,:));