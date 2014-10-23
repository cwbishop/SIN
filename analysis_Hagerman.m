function [target, noise] = analysis_Hagerman(results, varargin)
%% DESCRIPTION:
%
%   This function analyzes Hagerman-style (that is, phase inversion
%   technique) recordings to estimate the target/noise tracks, estimate
%   the noise floor of the playback/recording loop (this includes
%   environmental noise), and estimates the signal to noise ratio of the
%   input and output signals.
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
%   Parameters for Hagerman Labeling:
%
%   'target_string': string used to name the target (e.g., 'T')
%
%   'noise_string':     string used to name the noise (e.g., 'N')
%
%   'inverted_string':  string used to flag phase inverted target/noise
%                       (e.g., 'inv')
%
%   'original_string':  string used to flag non-phase inverted target/noise
%                       (e.g., 'orig')
%   
%   'pflag':     integer, sets plotting level. This parameter is inherited
%                by secondary functions as well. At time of writing, 2 is
%                the highest level of plotting detail. 0 means no plots. 
%
%   'absolute_noise_floor': string. This string is compared against
%                           all file names in the playback list. If a match
%                           is found, then this file is assumed to contain
%                           the absolute noise floor estimate, however the
%                           user decides to estimate it. This is typically
%                           done by recording "silence" for some period of
%                           time. 
%
%   'average_estimates':   bool, if set then the target waveforms are
%                          collapsed (temporally averaged) to create a
%                          single target waveform. Recall that the target
%                          can be estimated in two was ( (oo - oi)/2 and
%                          (io - ii)/2 ). The same is done for the noise
%                          waveform.
%
%                           Note: only "true" supported at time this was
%                           written. See development section for more
%                           notes. 
%
%   'channels': integer array, contains channel numbers to include in
%               Hagerman analysis. Note that the user should EXCLUDE all
%               channels that have no data (all zeros). On the Amp Lab PC,
%               that means only including channels 1 and 2. 
%
% OUTPUT:
%
%   results:    modified results structure with analysis results field
%               populated.
%
% Development:
%
%   1) Allow users to provide a string with tags in it (e.g.,
%   %%target_string%% to denote where labels should be in the file name. A
%   regular expression, perhaps? Currently, this is hard-coded. Could cause
%   some issues down the road if we decide to change the file name format. 
%
%   2) Allow users to break down SNR estimates by channel AND estimate
%   (recall that signal and noise can be estimated in two ways, each). The
%   code currently temporally averages these two estimates to get a concise
%   picture of what the SNR looks like.
%
%   3) Add in a binary masker for use in RMS calculations. This should
%   improve the accuracy of RMS calculations. 
%
%   4) Add in option for RMS estimation routine (e.g., unweighted,
%   A-weighted, etc.) 
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% GATHER FILENAMES AND RECORDINGS
filenames = results.RunTime.sandbox.playback_list; 
recordings = results.RunTime.sandbox.mic_recording; 

%% GET THE MIXER USED DURING PLAYBACK
mixer = results.RunTime.player.mod_mixer; 

%% GET SAMPLING RATE/NUMBER OF CHANNELS
fs = results.RunTime.player.record.device.DefaultSampleRate;

%% QUICK SAFETY CHECK
if numel(filenames) ~= numel(recordings)
    error('Number of filenames does not match the number of recordings'); 
end % if numel(fnames)

%% GROUP FILENAMES AND DATA TRACES
%   The data traces are the recordings written to the structure
for i=1:numel(filenames)
    data{i,1} = filenames{i};
    data{i,2} = recordings{i};
end % for i=1:numel ...

%% LOOK FOR NOISE FLOOR RECORDING
%   In some instances, the user may acquire an absolute noise floor
%   estimate - that is, a recording of "silence" to estimate the noise
%   levels in the sound playback/recording loop and any ambient noise. This
%   can be helpful for SNR estimation and correction or offline filter
%   design to remove (ambient) noise contaminants. 
noise_floor_mask = ~cellfun(@isempty, strfind(filenames, d.absolute_noise_floor)); 

% Sanity check to make sure there's only one noise floor estimate
if numel(noise_floor_mask(noise_floor_mask)) > 1
    error('More than one match found for noise floor estimation. Multiple estimates not supported (yet)');
end 

% Save the noise floor recording for further analysis below
noise_floor_recording = recordings{noise_floor_mask}(:,d.channels); 
noise_floor_rms = rms(noise_floor_recording); 

%% CLEAN FILENAMES FOR MATCHING
%   We want to strip the filenames of the target/noise inversion
%   information and just match the basenames. First step is to get the base
%   names. 
basename = cell(numel(filenames), 1); 
for i=1:numel(filenames)
    
    % Get the current file name
    tmp = filenames{i};
    
    % Remove all 4 possible naming combinations
    tmp = strrep(tmp, [d.target_string d.original_string d.noise_string d.original_string], ''); % +1, +1
    tmp = strrep(tmp, [d.target_string d.original_string d.noise_string d.inverted_string], '');  % +1, -1
    tmp = strrep(tmp, [d.target_string d.inverted_string d.noise_string d.inverted_string], '');  % -1, -1
    tmp = strrep(tmp, [d.target_string d.inverted_string d.noise_string d.original_string], '');  % -1, +1
    
    basename{i,1} = tmp;
    
    clear tmp
end % for i=1:numel(fnames)

%% GROUP FILES BY BASENAME
%   Now that we have the basenames for the original files, we can figure
%   out which recordings should be grouped together based on the filename
%   alone. 

% fgroup is a grouping variable
file_group =zeros(numel(filenames),1); 

% while ~isempty(basename)
for i=1:numel(basename)
    mask = false(numel(basename),1); 
    
    ind = strmatch(basename{i}, basename, 'exact'); 
    if file_group(ind(1)) == 0
       file_group(ind) = max(file_group)+1; 
    end % if fgroup
    
end % for i=1:numel(fnames)

%% NOW TOSS OUT GROUPS WITH FEWER THAN 4 SAMPLES
%   - Fewer than 4 samples will be found for noise floor matching. 
%   - This will implicitly remove the noise floor estimate, if it's here. 
group_numbers = unique(file_group);
for i=1:numel(group_numbers)
    
    if numel(file_group(file_group == group_numbers(i))) < 4
        file_group(file_group==group_numbers(i)) = NaN;
    end % if numel ...
    
end  % for i=1:numel(grps)

%% FOR REMAINING GROUPS, LOOP THROUGH AND PERFORM ANALYSES

% Number of groups tells us how many file groupings we have. This should
% correspond to the number of SNRs we have recorded. 
group_numbers = unique(file_group(~isnan(file_group))); 

% snr will tell us the SNR corresponding to each group. This is discovered
% below using some simple string matching. Granted, it assumes the filename
% structure (which is a little silly), but making this more flexible would
% probably take a lot of time to do. CWB isn't up for it at the moment. 

% snr_requested tells us what the user requested the SNR to be in the call
% to createHagerman
snr_requested = nan(numel(group_numbers), 1);

% snr_theoretical is the SNR derived from the wav files. Ideally,
% snr_requested and snr_theoretical should match very well
snr_theoretical = nan(numel(group_numbers), 1);

% snr_empirical is the SNR derived from the recordings. This should match
% snr_theoretical well in the unaided condition
snr_empirical = nan(numel(group_numbers), 1);

for i=1:numel(group_numbers)
    
    % Create logical mask
    mask = false(numel(file_group),1);
    mask(file_group == group_numbers(i)) = true; 
    mask = find(mask); % convert to indices.
    
    % Get the filenames from the data variable. Will use this to figure out
    % which data traces go where
    group_filenames = {data{mask,1}}; 
    
    % What's the SNR for this group of recordings?
    %   - We'll assume theres an SNR label in a ';' delimited file name.
    %   The SNR should be the first element in one segment of the file name
    %   - Also does a basic sanity check to (re)confirm that all files in
    %   this group have the same SNR according to this (clunky) algorithm
    for k=1:numel(group_filenames)
        
        % Get the individual sections
        filename_sections = strsplit(group_filenames{k}, ';'); 
        
        % Now find the SNR segment
        %   - This looks super complicated ... and it is. BUT seems to work
        %   - Should be insensitive to "SNR" string's case (snr or SNR both
        %   recognized) 
        snr_string = filename_sections(~cell2mat(cellfun(@isempty, strfind(cellfun(@lower, filename_sections, 'uniformoutput', false), 'snr'), 'uniformoutput', false))');
        
        % Get the leading digit. This should be our SNR value
        
        snr_string = regexp(snr_string,['[-]{0,1}\d+\.?\d*'],'match');
        temp_snr(k,1) = str2double(snr_string{1}); 
        
    end % for i=1:numel(group_filenames
    
    % Check to make sure there's only ONE SNR in this file group
    if numel(unique(temp_snr)) ~= 1
        error('Multiple SNRs found in this file group');
    else
        % Assign the SNR value to our SNR array. We'll use this below for
        % plotting/analysis purposes. 
        snr_requested(i) = unique(temp_snr); 
    end % if numel(unique ...
    
    % Create a variable to store data traces
    %   Col 1 = +1/+1
    %   Col 2 =  +1/-1
    %   Col 3 = -1/-1
    %   Col 4 = -1/+1    
    
    % Find +1/+1
    ind = findcell(group_filenames, [d.target_string d.original_string d.noise_string d.original_string]);
    oo_theoretical = SIN_loaddata(data{mask(ind), 1});
    oo_empirical = data{mask(ind), 2}; 
    
    % Extract the speech mask
    %   This is a logical vector written to file that tells us at which
    %   samples the signal is nominally present. Only these samples should
    %   be used in SNR estimation. 
    signal_mask = logical(oo_theoretical(:, end));     
    
    % Mix theoretical signal
    %   In order to derive the "theoretical" waveform, we need to mix the
    %   data with the mod_mixer used in player_main, then sum over
    %   channels.
    oo_theoretical = oo_theoretical * mixer; 
    
    % Now, sum over channels. This should give us an idea of what the
    % recorded waveform should look like in a perfect world. 
    oo_theoretical = sum(oo_theoretical, 2); 
    
    % Find +1/-1
    ind = findcell(group_filenames, [d.target_string d.original_string d.noise_string d.inverted_string]);
    oi_theoretical = SIN_loaddata(data{mask(ind), 1});
    oi_theoretical = oi_theoretical * mixer; 
    oi_theoretical = sum(oi_theoretical, 2);
    oi_empirical = data{mask(ind), 2}; 
    
    % Find -1/-1
    ind = findcell(group_filenames, [d.target_string d.inverted_string d.noise_string d.inverted_string]);
    ii_theoretical = SIN_loaddata(data{mask(ind), 1});
    ii_theoretical = ii_theoretical * mixer; 
    ii_theoretical = sum(ii_theoretical, 2);
    ii_empirical = data{mask(ind), 2}; 
    
    % Find -1/+1
    ind = findcell(group_filenames, [d.target_string d.inverted_string d.noise_string d.original_string]);
    io_theoretical = SIN_loaddata(data{mask(ind), 1});
    io_theoretical = io_theoretical * mixer; 
    io_theoretical = sum(io_theoretical, 2);
    io_empirical = data{mask(ind), 2};     
    
    % Get empirical target and noise waveforms
    [target_empirical{i}, noise_empirical{i}] = process_hagerman(...
        oo_empirical, oi_empirical, ii_empirical, io_empirical, fs, d); 
    
    % Get theoretical target and noise waveforms
    %   We have to replace d.channels with 1 since we will never have more
    %   than 1 channel
    td = d;
    td.channels = 1; 
    [target_theoretical{i}, noise_theoretical{i}] = process_hagerman(...
        oo_theoretical, oi_theoretical, ii_theoretical, io_theoretical, fs, td); 
    
end % for i=1:numel(grps)

% By this point, we should have an N-element cell array, where N is the
% number of SNRs tested. Each element should by a Txnumel(d.channels) array, where
% T is the number of samples and numel(d.channels) is the number of
% channels the user specifies in the analysis.

%% SORT TARGET/NOISE
%   Want the target/noise traces to be in ascending order of SNR.

% Get sorting index (I)
[~, I] = sort(snr_requested);

% Apply sorting index to target and noise tracks
target_empirical = {target_empirical{I}}';
target_theoretical = {target_theoretical{I}}';
noise_empirical = {noise_empirical{I}}';
noise_theoretical = {noise_theoretical{I}}';
snr_requested = snr_requested(I); 

%% ESTIMATE THEORETICAL SNR (RMS)
%   As a first pass, we'll take a look at the SNR as measured using a basic
%   RMS of the target_theoretical and noise_theoretical
for i=1:numel(target_theoretical)
    
    % Apply mask to target
    %   Recall that we used a signal mask to do the RMS estimation during
    %   stimulus creation. Now we'll use that SAME MASK to determine over
    %   which samples we should do our RMS estimation. 
    target_masked = target_theoretical{i}(signal_mask, :); 
    
    snr_theoretical(i, 1) = db(rms(target_masked)) - db(rms(noise_theoretical{i}));
    
end % i=1:numel(target_theoretical)

%% ESTIMATE EMPIRICAL SNR (RMS)
%   This process requires an additional realignment step. In a nutshell, we
%   must realign the recording with the original file in order to apply the
%   signal_mask to our RMS calculations.
snr_empirical = nan(numel(target_empirical), size(target_empirical{1},2)); 
for i=1:numel(target_empirical)
    
    % Realign each channel to the (summed) wav file. This should allow us
    % to apply the signal_mask to each channel independently.
    %
    % Note: we have to realign each channel because there's a high
    % probability that recordings will be slightly delayed between ears,
    % unless the experimenter is extremely careful and precise.    
    [aligned_theoretical, aligned_empirical, lag] = ...
            align_timeseries(target_theoretical{i}, ...
                target_empirical{i}, 'xcorr', 'fsx', fs, 'fsy', fs, 'pflag', d.pflag >= 2);

    % Create signal_mask for each channel and apply it to the data
    target_masked = [];
    for c=1:numel(lag)
        mask = logical([false(abs(lag(c)),1); signal_mask; false(size(target_empirical{i},1) - (abs(lag(c)) + numel(signal_mask)),1)]);
        target_masked(:,c) = target_empirical{i}(mask,c); 
    end % for c=1:numel(lag)
    
    % This gives a relative measure within each recording channel ... I
    % think. CWB is very tired and probably should not be writing this ...
    snr_empirical(i,:) = db(rms(target_masked)) - db(rms(noise_empirical{i})); 
    
end % for i=1:numel(target_empirical)

%% GENERATE PLOTS

if d.pflag > 0
    
    % Theoretical vs. Requested SNR plot
    %   This plot should help us quantify any slop in our analysis routine.
    %   There's no reason why the the theoretical and requested SNRs should
    %   not match point for point. Unless, of course, there's an error or
    %   something somewhere ... 
    figure, hold on
    
    % Plot unity line
    x = [min(min(snr_requested)):0.01:max(max(snr_requested))]';
    plot(x, x, 'k--', 'linewidth', 2)
    
    % Plot channel estimates
    plot(snr_requested, snr_theoretical, '*', 'linewidth', 1, 'markersize', 10)
    
    % Plot the absolute noise floor
%     plot(x*ones(1, numel(d.channels)), repmat(db(noise_floor_rms), length(x), 1), '--', 'linewidth', 1); 
    
    % Markup
    xlabel('Requested SNR (dB)');
    ylabel('Theoretical SNR (dB)'); 
    legend(strvcat('Perfect SNR', [repmat('SNR: Channel ', numel(d.channels)+1, 1) strvcat(num2str(d.channels'), 'Mean')], strvcat([repmat('Channel ', numel(d.channels), 1) num2str(d.channels') repmat(' Noise Floor', numel(d.channels), 1)])), 'location', 'eastoutside')    
    grid on
    
    % Empirical vs. Theoretical SNR plot
    figure, hold on
    
    % Plot unity line
    plot(x, x, 'k--', 'linewidth', 2)
    
    % Plot channel estimates
    plot(snr_theoretical*ones(1, size(snr_empirical,2)), snr_empirical, '*', 'linewidth', 1, 'markersize', 10)
    
    % Plot mean(across channel) estimates
    plot(mean(snr_theoretical, 2), mean(snr_empirical,2), 'sk', 'linewidth', 2); 
    
    % Plot the absolute noise floor
%     plot(x*ones(1, numel(d.channels)), repmat(db(noise_floor_rms), length(x), 1), '--', 'linewidth', 1); 
    
    % Markup
    xlabel('Theoretical SNR (dB)');
    ylabel('Empirical SNR (dB)'); 
    legend(strvcat('Unity', [repmat('SNR: Channel ', numel(d.channels)+1, 1) strvcat(num2str(d.channels'), 'Mean')], strvcat([repmat('Channel ', numel(d.channels), 1) num2str(d.channels') repmat(' Noise Floor', numel(d.channels), 1)])), 'location', 'eastoutside')    
    grid on
    
end % if d.pflag

function [target, noise] = process_hagerman(oo, oi, ii, io, fs, varargin)
%% DESCRIPTION:
%
%   This function estimates the target and noise tracks extracted from the
%   files above. 
%
% INPUT:
%
%   oo, oi, ii, io: 
%
% Parameters:
%
%   'average_estimates'
%
% OUTPUT:
%
%
%% GET INPUT PARAMETERS
d = varargin2struct(varargin{:});

% Number of channels
%   Assumes that all data traces have the same number of channels
number_of_channels = size(oo,2); 

% Calculate the target signal by averaging over the two ways we can
% solve for the target. These will be averaged below

if d.average_estimates

    % Compute target and noise samples in two ways each. These
    % estimates will be checked for temporal alignment below. 
    %
    % Note that the second estimate's polarity is inverted (multiplied
    % by -1) so the polarities match. 
    target   = [Hagerman_getsignal(oo, oi, 'fsx', fs, 'fsy', fs, 'pflag', d.pflag>=2) Hagerman_getsignal(io, ii, 'fsx', fs, 'fsy', fs, 'pflag', false).*-1 ]; 
    noise    = [Hagerman_getsignal(oo, io, 'fsx', fs, 'fsy', fs, 'pflag', d.pflag>=2) Hagerman_getsignal(oi, ii, 'fsx', fs, 'fsy', fs, 'pflag', false).*-1 ]; 

    % Check alignment of each channel
    target_lag = [];
    noise_lag = [];
    aligned_noise1 = {};
    aligned_noise2 = {};        
    aligned_target1 = {};
    aligned_target2 = {}; 
    for c=1:numel(d.channels)

        % Check noise alignment
        [aligned_noise1{c}, aligned_noise2{c}, noise_lag(c,1)] = ...
            align_timeseries(noise(:,d.channels(c)), noise(:,d.channels(c) + number_of_channels), 'xcorr', 'fsx', fs, 'fsy', fs, 'pflag', d.pflag >= 2);

        % Check target alignment
        [aligned_target1{c}, aligned_target2{c}, target_lag(c,1)] = ...
            align_timeseries(target(:,c), target(:,c + number_of_channels), 'xcorr', 'fsx', fs, 'fsy', fs, 'pflag', d.pflag>=2);

    end % for c=1:number_of_channels

    % Error checking for temporal alignment. If we plan to temporally
    % average over the two target/noise estimates, then they need to be
    % *perfectly* aligned. Verify that empirically with
    % align_timeseries.

    % Verify that the targets and noise estimates are well-aligned
    if any(noise_lag ~= 0) 

        error('Temporal misalignment in noise estimates. No recovery coded, but it can be.')                

    else
        % Average over noise estimates
        noise = (noise(:,d.channels) + noise(:,d.channels + number_of_channels)) ./ 2;
    end % if noise_lag ~= 0

    if any(target_lag ~= 0)

        error('Temporal misalignment in target estimates. No recovery coded, but it can be.')

    else
        % Average over target estimates
        target = (target(:,d.channels) + target(:,d.channels + number_of_channels)) ./ 2;
    end % if target_lag ~= 0

else
    error('Unsupported option ... see development'); 
end 