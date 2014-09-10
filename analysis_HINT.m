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
%   'tmask':    DxP logical mask applied to player.mod_mixer and
%               sandbox.mod_mixer for speech track SNR levels. Assumes a
%               scaling factor of 1 corresponds to 0 dB SNR. 
%
%   'plot':     bool, if set, creates a series of summary plots for user
%               perusal.
%
%   'RTSest':   string, specifying the RTS estimation routine to use. This
%               may be expanded later if different estimation approaches
%               are required.
%
%                   'traditional':  RTS is estimated by averaging signal
%                                   level (assumed to be equivalent to SNR,
%                                   see 'tmask' notes and notes in
%                                   description) over trials 5:N+1, where N
%                                   is the number of sentences used in the
%                                   test.
%               
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

%% ADJUST AND APPEND EXTRAPOLATED dB VALUE
%   - HINT scoring requires us to estimate the dB value of the *next* trial
%   (e.g., trial 21 in a 20 trial test) for scoring purposes. 
%   - We can do this by determining the algorithm used, then getting the
%   mod_code, then running the modifiers in sequence. 

% Get runtime structure from results
runtime = results.RunTime; 

% Choose which algo we're supposed to use
algo = HINT_chooseAlgo(runtime.player.modcheck.algo, runtime.player.modcheck.startalgoat, runtime.sandbox.trial);

% Get mod_code
mod_code = algo(runtime.player.modcheck.score);

% Run modifiers to see if the mod_mixer changes
for i=1:length(runtime.player.modifier)
    
    % Change modifier number. This is how the adaptive player tracks which
    % modifier its using. Oh, the things I would do differently in
    % hindsight. 
    runtime.sandbox.modifier_num = i; 
    
    % Now call the modifier(s)
    [~, runtime] = runtime.player.modifier{i}.fhandle([], mod_code, runtime); 
end % 

%% GET MOD_MIXER HISTORY FROM SANDBOX FIELD
%   This includes the value we just appended through the modifiers. 
modmix = runtime.sandbox.mod_mixer;

%% EXPAND LOGICAL MASK
tmask = logical(repmat(d.tmask, 1, 1, size(modmix, 3))); 

%% GET TIME SERIES
%   - Extract the existing time series and convert to decibel (dB) scale
ts = db(modmix(tmask), 'voltage');

%% CALCULATE RTS
switch d.RTSest
    case {'traditional'}
        % Implements a traditional scoring method as described in HINT
        % manual.
        RTSmask = 5:length(ts);
        
    otherwise
        error('Unknown RTS estimation routine. Check RTSest field.');        
end % switch d.RTSest

%% APPEND DATA TO ANALYSIS
%   RTS:
rts = mean(ts(RTSmask));
results.analysis.results = struct( ....
    'RTS',  rts); % 

%% CREATE PLOTS
if d.plot
    
    h = figure;
    
    % Plot timeseries
    lineplot2d(1:length(ts), ts, ...
        'grid', 'on', ...
        'linewidth', 2, ...
        'marker',   's', ...
        'fignum',   h); 
    
    % Plot points used in RTS
    lineplot2d(RTSmask, ts(RTSmask), ...
        'color',    'r', ...
        'grid', 'on', ...
        'linewidth', 2, ...
        'marker',   'o', ...
        'fignum',   h); 
    
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
        'legend',   {{'Time Course', 'RTS Trials', 'RTS Est.'}}, ...
        'fignum',   h);
    
end % if d.plot
