function results = analysis_ANL(results, varargin)
%% DESCRIPTION:
%
%   Analysis function for ANL testing. 
%
% INPUT:
%
%   results:   data information. Can be one of the following formats
%               - results structure from SIN_runTest.
%               - string, path to a mat file containing the results 
%               structure. 
%
% Parameters:
%
%   'order':    integer vector, where each element relates the correct
%               results structure to the (hard-coded) testing condition.
%               The (hard-coded) test order is as follows:
%
%                   first:  Speech too loud
%                   second: speech too quiet
%                   third:  most comfortable level (MCL)
%                   fourth: noise too loud
%                   fifth:  noise quiet
%                   sixth:  background noise level (BNL)
%
%               As an example, consider a case where the test is
%               administered in the following order: noise too loud, noise
%               quiet, background noise level (BNL), speech too loud,
%               speech too quiet, MCL. 
%
%               The user would have to specify the order as follows:
%                   order = [4 5 6 1 2 3];
%
%               An incorrect mapping may lead to spurious, nonsensical
%               results.     
%
%   'tmask':    DxP weighting mask applied to player.mod_mixer to determine
%               the scaling factor of the speech track. Should only contain
%               a single true value.               
%
%   'nmask':    like tmask, but for noise track. Should also only contain a
%               single true value
%
%   'plot':     bool, set to true to create summary plots. Set to false to
%               suppress plotting. 
%
% OUTPUT:
%
%   results:    results structure with modified 'analysis' field. Note that
%               only the first element of the results structure will be
%               modified. 
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% INPUT CHECK
if numel(d.nmask(d.nmask))~=1, error('incorrect nmask'); end
if numel(d.tmask(d.tmask))~=1, error('incorrect tmask'); end

%% LOAD RESULTS, IF NECESSARY
if ischar(results)
    results = load(results);
    results = results.results;
end % if ischar(results)

%% CALCULATE ANL
MCL = db(results(d.order(3)).RunTime.player.mod_mixer(d.tmask), 'voltage'); % Most Comfortable Level
BNL = db(results(d.order(6)).RunTime.player.mod_mixer(d.nmask), 'voltage'); % Background Noise Level

ANL = MCL - BNL; 

%% APPEND DATA TO ANALYSIS FIELD OF RESULTS
results(1).RunTime.analysis.results = struct( ...
    'mcl',  MCL, ...
    'bnl',  BNL, ...
    'anl',  ANL); 

%% CREATE SUMMARY PLOTS
if d.plot
    
    figure, hold on
    
    % Plot MCL/BNL
    plot(1, MCL, 'bs', 'linewidth', 3)
    plot(2, BNL, 'ks', 'linewidth', 3)
     
    % Plot "Too Loud" information
    data = db([results(d.order(1)).RunTime.player.mod_mixer(d.tmask) results(d.order(6)).RunTime.player.mod_mixer(d.nmask)]);
    plot(1:2, data, 'r^', 'linewidth', 1.5);
    
    % Plot too quiet information
    data = db([results(d.order(2)).RunTime.player.mod_mixer(d.tmask) results(d.order(5)).RunTime.player.mod_mixer(d.nmask)]);
    plot(1:2, data, 'co', 'linewidth', 1.5);
    
    % Plot ANL
    plot(1.5, ANL, 'r*', 'linewidth', 2)
    % Set axis limits
   	xlim([0.5 2.5]);     
     
    % Turn grid on
    grid
    
    % Markup
    title(results(1).RunTime.specific.testID); 
    legend('MCL', 'BNL', 'Loud', 'Quiet', 'ANL', 'location', 'best');    
    ylabel('dB SPL (re: reference)'); 
    set(gca, 'XTick', [1 2])
    set(gca, 'XTickLabel', {'Speech', 'Noise'})
        
end % if d.plot