function results = analysis_AudioTest(results, varargin)
%% DESCRIPTION:
%
%   Function designed to perform some basic sanity checks on the sound
%   playback/recording loop. Tests the following and perhaps more ... who
%   knows if CWB updated the help file ;). Designed to be paired with Audio
%   Test (10 Hz Click Train). See SIN_TestSetup for details. 
%
%       Playback/Record Reliability: A basic timing test to compare the
%       relative timing of recordings of the same sound presented through
%       the same playback/recording loop repeatedly. 
%
%       Level Check: checks the relative mic levels.    
%   
% INPUTS:
%
%   results:    a results structure from SIN's player_main or other
%               compatible results structure.
%
% Parameters:
%
%   'plot':     integer, plotting level detail.
%                   0: no plots
%                   1: summary plots (histograms and the like)
%                   2: detailed plots (creates LOTS of plots). 
%
%   'chans':    integer array, channels to test realignment. Set if only a
%               subset of  channels have data in them, otherwise
%               align_timeseries might buck. 
%
%   'dBtol':    double, decibel tolerance. If this tolerance value is
%               exceeded, the analysis will generate a warning. 
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
%   results:    results structure with updated analysis field. 
%
% Development:
%
%   - Add an analysis of frequency response. This could be done on a
%   temporally averaged waveform, provided the timing is OK. Actually, this
%   might be better handled with a standalone test. 
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

%% For each channel, realign all signals to first data trace
lags = nan(numel(recs)-1, numel(d.chans)); 
rmslevels = nan(numel(recs), numel(d.chans));
peaklevels = nan(numel(recs), numel(d.chans));

% Keep track of an average time series per channel
average_time_series = []; 

% Do we need to design a filter?
%   We will only estimate filter coefficients if the user wants to apply a
%   filter below.
if d.apply_filter
    
    % Note that frequency vector is normalized to Nyquist
    [b, a] = butter(d.filter_order, d.filter_frequency_range./(FS/2), d.filter_type);
    
end % d.apply_filter

for c=1:numel(d.chans) % loop through all channels
    
    % Massage data into a sensible matrix for easier analysis
%     data = nan(max_recording_length, numel(recs)); 
    for i=1:numel(recs)
        data(:,i) = recs{i}(:,d.chans(c));        
    end % for i=1:numel(recs)
    
    % Apply filter, if necessary
    if d.apply_filter
        data = filtfilt(b,a,data); 
    end % if d.apply_filter
    
    % Level Test
    rmslevels(:,c) = rms(data); 
    peaklevels(:,c) = max(abs(data));
    
    % Timing Test
    % Translate d.plot to pflag for align_timeseries
    if d.plot == 2, pflag = 1; else, pflag = 0; end
    
    % Align timeseries, generate some plots    
    [X, Y, lags(:,c)] = align_timeseries(data(:,1), data(:, 2:end), 'xcorr', ...        
        'pflag',    pflag, ...
        'yoke', false, ...
        'fsx',  FS, ...
        'fsy',  FS);
    
    % add data to the average time series
    if isempty(average_time_series)
        average_time_series = zeros(size(data,1), numel(d.chans));
    end % if isempty(average_time_series)
    
    % Compute average time series
    average_time_series(:,c) = mean(data,2); 
    
end % for c=1:size(recs{1}, 2)

% CONVERT LAGS TO SECONDS
lags = lags ./ FS; 

% ALIGNMENT WARNING
%   Throw alignment warning if recordings are not well matched
if max(abs(lags)) > 0 
    warning('Misalignment detected'); 
end % if max ...

% LEVELS WARNING
% maxrmsdiff = max(abs(diff(db(rmslevels,1,2))));
maxrmsdiff = db(max(max(rmslevels))) - db(min(min(rmslevels)));
if maxrmsdiff > d.dBtol
    warning(['Channel RMS differ by ' num2str(maxrmsdiff) ' dB. This exceeds the specified tolerance of ' num2str(d.dBtol) ' dB.'])
end % maxrmsdiff

maxpeakdiff = db(max(max(peaklevels))) - db(min(min(peaklevels)));
if maxpeakdiff > d.dBtol
    warning(['Channel PEAKS differ by ' num2str(maxpeakdiff) ' dB. This exceeds the specified tolerance of ' num2str(d.dBtol) ' dB.'])
end % maxrmsdiff

% PLOT LEVELS
if d.plot
    figure, hold on
    
    % Plot RMS Levels
    plot(1.*ones(size(rmslevels)), db(rmslevels), 's')
    
    % plot Peak levels
    plot(2.*ones(size(peaklevels)), db(peaklevels), 's')
    
    % Set X-axis labels
    set(gca, 'XTick', [1 2]);
    set(gca, 'XTickLabel', {['RMS (max diff: ' num2str(maxrmsdiff) ')'], ['Peak (max diff: ' num2str(maxpeakdiff) ')']});
    xlim([0.5 2.5]);
    ylabel('dB (RE: 1)')
    grid; 
    
    legend([repmat('Chan ', 2, 1) num2str([1:2]')], 'location', 'best');
end % d.plot

% PLOT INTRAaural ALIGNMENT HISTOGRAM
%   Create a histogram of lags, if user asks us to. 
if d.plot
    
    figure
    
    % Create histogram
    hist(lags, 100); 
    
    % Markup 
    title('INTRAaural Temporal Alignment'); 
    xlabel('Lags (s)')
    ylabel('Frequency'); 
    
end % if d.plot 

% PLOT AVERAGE WAVEFORM
if d.plot
    
    data = {};
    for i=1:size(average_time_series,2)
        data{i} = average_time_series(:,i); 
    end % for i
    
    plot_waveform(data, FS); 
    
end % d.plot