function results = analysis_TimingTest(results, varargin)
%% DESCRIPTION:
%
%   Function to analyze a basic timing test of the playback/recording loop.
%   Much of this is simply a wrapper for align_timeseries, which will align
%   any two (or more) time series to a reference series. It returns, among
%   other things, a lag estimate between two time series. We'll use this
%   value to create a histogram.
%   
% INPUTS:
%
%   results:    a results structure from SIN's player_main or other
%               compatible results structure.
%
% Parameters:
%
%   'plot':     bool, if true, plots are generated.
%
%   'chans':    integer array, channels to test realignment. Set if only a
%               subset of  channels have data in them, otherwise
%               align_timeseries might buck. 
%
% OUTPUT:
%
%   results:    results structure with updated analysis field. 
%
% Development:
%
%   None (yet).
%
% Christopher W Bishop
%   University of Washington 
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% GET RECORDED DATA
% Grab mic recordings from results structure
recs = results.RunTime.sandbox.mic_recording; 
FS = results.RunTime.player.record.device.DefaultSampleRate;

%% FOR EACH CHANNEL, REALIGN ALL SIGNALS TO FIRST DATA TRACE
lags = nan(numel(recs)-1, numel(d.chans)); 

for c=1:numel(d.chans) % loop through all channels

    % Massage data into a sensible matrix for easier analysis
    data = [];
    for i=1:numel(recs)
        data(:,i) = recs{i}(:,d.chans(c));
    end % for i=1:numel(recs)
    
    % Align timeseries, generate some plots
    [X, Y, lags(:,c)] = align_timeseries(data(:,1), data(:, 2:end), 'xcorr', ...        
        'pflag',    d.plot, ...
        'yoke', false, ...
        'fsx',  FS, ...
        'fsy',  FS);
    
%     lags(:,c) = tlags; 
    
    % Store X, Y, and figure in results structure. 
    

end % for c=1:size(recs{1}, 2)

%% CONVERT LAGS TO SECONDS
lags = lags ./ FS; 

%% ALIGNMENT WARNING
%   Throw alignment warning if recordings are not well matched
if max(abs(lags)) > 0 
    warning('Misalignment detected'); 
end % if max ...

%% PLOT HISTOGRAM
%   Create a histogram of lags, if user asks us to. 
if d.plot
    
    figure
    
    % Create histogram
    hist(lags, 100); 
    
    % Markup 
    xlabel('Lags (s)')
    ylabel('Frequency'); 
    
end % if d.plot 