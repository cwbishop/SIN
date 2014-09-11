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
    
    % Save figure handle for saving purposes below
    h = figure; 
    hold on
    
    % Plot MCL/BNL
    plot(1, MCL, 'bs', 'linewidth', 3)
    plot(2, BNL, 'ks', 'linewidth', 3)
     
    % Plot "Too Loud" information
    data = db([results(d.order(1)).RunTime.player.mod_mixer(d.tmask) results(d.order(4)).RunTime.player.mod_mixer(d.nmask)]);
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
     
    % Create a plot of all data channels
    %   Useful for spotting issues with scaling values
    
    for i=1:numel(results)        
        mmixer = results(i).RunTime.sandbox.mod_mixer; 
        
        % X is the number of segements
        x = 1:size(mmixer, 3); 
        
        % y is the scale factor
        y = [];        
        for c=1:size(mmixer,3)
            y(c,:) = reshape(mmixer(:,:,c), 1, size(mmixer,1)*size(mmixer,2));
        end % for i=1:size(mmixer)
        
        % Replace 0 values with NaN. Zeros will cannot be log transformed
        % to dB space.
        y(y==0) = NaN; 
        
        % Convert to dB
        y = db(y); 
        
        % Create legend
        L ={};
        for c=1:size(mmixer,1)
            for k=1:size(mmixer,2)
                L{end+1} = ['DChan: ' num2str(c), ', PChan: ' num2str(k)];
            end 
        end 
        lineplot2d(x, y, 'xlabel', 'Block #', 'ylabel', 're: dB SPL', 'title', results(i).RunTime.specific.testID, 'legend', {L}, 'grid', 'on', 'linewidth', 2, 'legend_position', 'best', 'marker', 'o', 'fignum', h+i);
        
    end % for i=1:numel(results)
    
end % if d.plot