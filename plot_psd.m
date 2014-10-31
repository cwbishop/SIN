function [Pxx, freqs] = plot_psd(x, estimator, varargin)
%% DESCRIPTION:
%
%   Plot the power spectral density (PSD) of a time series or multiple time
%   series. Spectral estimation computed using Welch's periodogram (see doc
%   PWELCH for details). 
%
% INPUT:
%
%   x:  C-element cell array, where C is the number of time series the user
%       would like to plot. Alternatively, this can be a cell array of file
%       names ... pretty much anything that SIN_loaddata supports. 
%
%   estimator:          the function handle of the spectral estimator the
%                       user wants to use (e.g., @pwelch). The spectral
%                       estimator must return power estimates (pxx) and
%                       frequencies (normalized or otherwise). See pmtm for
%                       an alternative spectral estimator.
%
% Parameters:
%
%   A cell array of parameters that will be passed directly to the spectral
%   estimator. 
%
% OUTPUT:
%
%   Pxx:    power spectral density (PSD) estimates returned from estimator.
%
%   freqs:  frequencies returned from spectral estimator
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   10/14

% Initialize return variables
Pxx = {}; 
freqs = {}; 

% Open figure
figure, hold on

% Get colors for traces
[colorDef, ~]=erplab_linespec(numel(x));

% Make Legend
for i=1:numel(x)
    legend_text{i} = ['Series ' num2str(i)];
end 

% Loop through all time series.
for i=1:numel(x)
    
    % Load the time series
    time_series = SIN_loaddata(x{i}); 
    
    % Compute PSD
    [pxx, f] = estimator(time_series, varargin{:}); 
    
    % Plot the PSD 
    lineplot2d(f, db(pxx, 'power'), ...
        'xlabel',   'Frequency (Hz)', ...
        'ylabel',   'PSD (dB/Hz)', ...
        'title',    '', ...          
        'grid',     'on', ...
        'linewidth', 2, ...
        'color',    colorDef{i}, ...
        'fignum',   gcf); 
    
    % Add figure legend
    if i == numel(x)
        legend(legend_text, 'location', 'EastOutside')
    end % if i == numel(x)
    
    % Set x-axis to log scale
    set(gca, 'XScale', 'log')
    y = ylim;
    ylim([y(1) 0]); 
        
    % Add to Pxx/freqs
    Pxx{i} = pxx;
    freqs{i} = f; 
    
    
end % for i=1:numel(x)