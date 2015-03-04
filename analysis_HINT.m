function results = analysis_HINT(results, varargin)
%% DESCRIPTION:
%
%   Analysis script for HINT administered under various circumstances
%   (e.g., different algorithms, etc.). 
%
%   RTS estimation is currently done as described in the HINT manual (e.g.,
%   averaging over trials 5 :(N+1), where N is the total number of trials.
%   A "trial" is added on for scoring purposes. 
%
%   Note: the code implicitly assumes that a scaling factor of 1 applied to
%   the speech track leads to an SNR of 0 dB. If this is not the case, then
%   absolute measures should be interpreted with considerable caution.
%   Relative values should still be OK, thinks CWB. But I'm tired and
%   bored and have kinks in my legs from sitting, just sitting here day
%   after day. It's work, how I hate it, I'd much rather play. I'd take a
%   vacation, fly off for a rest, if I could find someone to ... do my
%   coding for me??? Thank you, Dr.Seuss for saving my brain.
%
%   For details, see
%   https://drive.google.com/a/uw.edu/?tab=mo#folders/0B0KUD8bhR_N_OFZRaFhCWEsxQkU
%
%   and
%
%   https://drive.google.com/a/uw.edu/?tab=mo#folders/0B0KUD8bhR_N_OFZRaFhCWEsxQkU
%
% INPUT:
%
%   results:    the results structure returned from SIN_runTest.m
%
% Parameters:
%
%   'channel_mask':    DxP logical mask applied to player.mod_mixer and
%               sandbox.mod_mixer for speech track SNR levels. Assumes a
%               scaling factor of 1 corresponds to 0 dB SNR. 
%
%   'plot':     bool, if set, creates a series of summary plots for user
%               perusal.
%
%   'include_next_trial':   bool, if included, we will estimate the SNR of
%                           what would be the next trial. This should be
%                           set to true for traditional HINT scoring as
%                           described in the CD manual.
%
%                           Note: the user should carefully consider
%                           whether or not to set this flag when using the
%                           'reversal_mean' RTS estimation approach below
%                           since the algorithm may in fact estimate the
%                           next trial as a reversal as well. The decision
%                           will depend heavily on the modifier behavior
%                           associated with the test and how it terminates.
%                           CWB cannot provide strong guidelines here. 
%
%                           Note: there is a safeguard put in place here in
%                           case the mod_mixer is tracked and appended
%                           before the stimulus is presented/scored. This
%                           scenario should be handled semi-intelligently,
%                           but the user should spot check to make sure the
%                           correct number of trials/reversals are being
%                           used in the average. 
%
%   'RTSest':   string, specifying the RTS estimation routine to use. This
%               may be expanded later if different estimation approaches
%               are required.
%               
%                   'trial_mean':   user wants to specify which trials to
%                                   average over to estimate RTS. Trial
%                                   mean will include all trials from
%                                   'startattrial':end. 'startat' field
%                                   below must correspond to the first
%                                   trial the user wishes to include in the
%                                   trial average. 

%                                   This estimation approach is most
%                                   closely linked to the "traditional"
%                                   HINT scoring procedure, as described in
%                                   the CD manual. 
%
%                   'reversal_mean':    average over reversal points. 
%
%   'start_at_trial':   integer, the first trial that should be considered
%                       in the mod_mixer time series. (required for all
%                       scoring approaches) 
%
%   'trials_to_score':  integer, the number of trials to include in the
%                       scoring (or reversal detection). If Inf, all trials
%                       after the start_at_trial are considered. Otherwise,
%                       trials are limited to
%                       start_at_trial:start_at_trial+trials_to_score. Only
%                       these trials will be included considered for all
%                       scoring approaches (mean, reversal_mean, etc.).
%                       (default = Inf)
%
%   'start_at_reversal':    integer, the first reversal that should be
%                           considered in the time series. (Only necessary
%                           for 'reversal_mean' scoring). 
%               
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% MULTI-STAGE TEST
%   Most implementations of HINT are seen as two-stage tests. We want the
%   scoring to be based of the last segment (typically)
runtime = results(end).RunTime;
    
%% ADJUST AND APPEND EXTRAPOLATED dB VALUE
%   - HINT scoring requires us to estimate the dB value of the *next* trial
%   (e.g., trial 21 in a 20 trial test) for scoring purposes. 
%   - We can do this by determining the algorithm used, then getting the
%   mod_code, then running the modifiers in sequence.  
%   
%   Note: we may not always need to do this because some runs may terminate
%   before all trials have been presented. This leads to mod_mixer having
%   an additional "trial" added to it without the stimulus being presented.
%   So we need a check to see if this is the case and, if so, we don't need
%   to tack on a new trial. The best way to do this at present is to check
%   the mic_recording to see if the recordings were gathered (at the end
%   each trial).

% Save the TOTAL TRIALS to a constant
TOTAL_TRIALS = length(runtime.sandbox.mic_recording);

% Truncate the mod mixer to match the number of actual trials presented.
runtime.sandbox.mod_mixer = runtime.sandbox.mod_mixer(:,:,1:TOTAL_TRIALS);

% Append an "additional" trial if include_next_trial is true
if d.include_next_trial
    
    % Increase the trial number for indexing purposes.
    runtime.sandbox.trial = TOTAL_TRIALS + 1; 
    
    % Choose which algo we're supposed to use
    [algo_handle, algo_index] = HINT_chooseAlgo(runtime.player.modcheck.algo, runtime.player.modcheck.startalgoat, runtime.sandbox.trial);

    % Get mod_code
    mod_code = algo_handle({runtime.player.modcheck.score{runtime.player.modcheck.startalgoat(algo_index):end}});

    % Run modifiers to see if the mod_mixer changes
    for i=1:length(runtime.player.modifier)

        % Change modifier number. This is how the adaptive player tracks which
        % modifier its using. Oh, the things I would do differently in
        % hindsight. 
        runtime.sandbox.modifier_num = i; 

        % Now call the modifier(s)
        [~, runtime] = runtime.player.modifier{i}.fhandle([], mod_code, runtime); 
    end % 

% elseif (numel(runtime.sandbox.mic_recording) ~= size(runtime.sandbox.mod_mixer,3)) && ~d.include_next_trial 
%     % Here, we the next trial has already been estimated during sound
%     % playback (although the last sound was not presented). User does not
%     % want to include the next trial, so we trim it out.
%     runtime.sandbox.mod_mixer = runtime.sandbox.mod_mixer(:,:,1:end-1);
end % 

% Sanity check to make sure we don't have too many trials in the mod_mixer
%   These two fields should never differ by more than a single trial. If
%   they do, then we throw an error here. 
if size(runtime.sandbox.mod_mixer,3) - numel(runtime.sandbox.mic_recording) > 1
    
    % These two fields should *never* differ by more than a single "trial".
    % If they do, then throw an error because something serious is amiss.
    error('Trial number mismatch');
    
end % if size( ...

%% GET MOD_MIXER HISTORY FROM SANDBOX FIELD
%   This includes the value we just appended through the modifiers. 
modmix = runtime.sandbox.mod_mixer;

%% EXPAND LOGICAL MASK
channel_mask = logical(repmat(d.channel_mask, 1, 1, size(modmix, 3))); 

%% GET TIME SERIES
%   - Extract the existing time series and convert to decibel (dB) scale
time_series = db(modmix(channel_mask), 'voltage');

%% TRIM TIME SERIES
%   Remove the trials we don't want to use in scoring.

% Need to handle the "Inf" case here if users want to include all trials.
if d.trials_to_score == Inf
    
    % Need to add the 1 because we subtract 1 below. 
    d.trials_to_score = length(time_series) - d.start_at_trial + 1;
end % 
time_series_trim = time_series(d.start_at_trial:d.start_at_trial + d.trials_to_score - 1); 

%% CALCULATE RTS
switch d.RTSest
    
    case {'trial_mean'}
        % Average over all trials starting at start_at. 
        rts_mask = 1:length(time_series_trim); 
        
    case {'reversal_mean'}
        % Estimate based on reversal values.
        
        % Find the N : N + whatever reversals
        is_rev = is_reversal(time_series_trim);
        rev_mask = find(is_rev); 
        
        % Create RTSmask
        rts_mask =  rev_mask(d.start_at_reversal:end);          
        
    otherwise
        error('Unknown RTS estimation routine. Check RTSest field.');        
end % switch d.RTSest

%% APPEND DATA TO ANALYSIS
%   RTS:
rts = mean(time_series_trim(rts_mask));
results(end).analysis.results = struct( ....
    'rts',  rts); % 

% Print SRT value to terminal
%   This makes it easier to copy/paste into
display(['SRT = ' num2str(rts)]); 

%% CREATE PLOTS
if d.plot
    
    h = figure;
    
    % Plot timeseries
    lineplot2d(1:length(time_series), time_series, ...
        'grid', 'on', ...
        'linewidth', 2, ...
        'marker',   's', ...
        'fignum',   h); 
    
    % Plot points used in RTS
    plot(d.start_at_trial + rts_mask -1, time_series_trim(rts_mask), ...
        'ro', 'linewidth', 2); 
    
    % Plot RTS
    lineplot2d(1, rts, ...
        'xlabel',   'Trial #', ...
        'ylabel',   'SNR (dB SPL)', ...
        'title',    runtime.specific.testID, ...
        'color',    'b', ...
        'grid', 'on', ...
        'linewidth', 3, ...
        'marker',   's', ...
        'linestyle', '', ...
        'legend',   {{'Time Course', 'SRT Trials', 'SRT Est.'}}, ...
        'fignum',   h);
    
    % Label the rts point
    label_datapoint(-10, rts-3, 'text', ['SRT = ', num2str(rts)], 'color', 'b', 'fontsize', 12, 'fontweight', 'bold');    
    
    % Add Figure to results structure
    results(end).analysis.results.figure = handle2struct(h); 
    
end % if d.plot
