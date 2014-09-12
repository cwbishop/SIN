function results = analysis_Hagerman(results, varargin)
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
%   'tstr': 
%   'nstr': 
%   'invstr':
%   'origstr':
%
%   'plot':     bool, if set, generate summary plots.
%
% OUTPUT:
%
%   results:    modified results structure with analysis results field
%               populated.
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

%% GATHER FILENAMES AND RECORDINGS
fnames = results.RunTime.sandbox.playback_list; 
recs = results.RunTime.sandbox.mic_recording; 

%% GET SAMPLING RATE/NUMBER OF CHANNELS
FS = results.RunTime.player.record.device.DefaultSampleRate; 
NCHANS = results.RunTime.player.record.device.NrInputChannels;

%% TEMPORARY STORAGE VARIABLES
OUT=[];

%% QUICK SAFETY CHECK
if numel(fnames) ~= numel(recs)
    error('Number of filenames does not match the number of recordings'); 
end % if numel(fnames)

%% GROUP FILENAMES AND DATA TRACES
%   The data traces are the recordings written to the structure
for i=1:numel(fnames)
    data{i,1} = fnames{i};
    data{i,2} = recs{i};
end % for i=1:numel ...

%% CLEAN FILENAMES FOR MATCHING
%   We want to strip the filenames of the target/noise inversion
%   information and just match the basenames. First step is to get the base
%   names. 
for i=1:numel(fnames)
    
    % Get the current file name
    tmp = fnames{i};
    
    % Remove all 4 possible naming combinations
    tmp = strrep(tmp, [d.tstr d.origstr d.nstr d.origstr], ''); % +1, +1
    tmp = strrep(tmp, [d.tstr d.origstr d.nstr d.invstr], '');  % +1, -1
    tmp = strrep(tmp, [d.tstr d.invstr d.nstr d.invstr], '');  % -1, -1
    tmp = strrep(tmp, [d.tstr d.invstr d.nstr d.origstr], '');  % -1, +1
    
    basename{i,1} = tmp;
    
    clear tmp
end % for i=1:numel(fnames)

%% GROUP FILES BY BASENAME
%   Now that we have the basenames for the original files, we can figure
%   out which recordings should be grouped together based on the filename
%   alone. 

% fgroup is a grouping variable
fgroup =zeros(numel(fnames),1); 

% while ~isempty(basename)
for i=1:numel(basename)
    mask = false(numel(basename),1); 
    
    ind = strmatch(basename{i}, basename, 'exact'); 
    if fgroup(ind(1)) == 0
       fgroup(ind) = max(fgroup)+1; 
    end % if fgroup
    
end % for i=1:numel(fnames)

%% GROUP FILENAMES AND DATA TRACES

%% NOW TOSS OUT GROUPS WITH FEWER THAN 4 SAMPLES
%   - Fewer than 4 samples will be found for noise floor matching. 
grps = unique(fgroup);
for i=1:numel(grps)
    if numel(fgroup(fgroup == grps(i)))<4
        fgroup(fgroup==grps(i)) = NaN;
    end % if numel ...
end  % for i=1:numel(grps)

%% FOR REMAINING GROUPS, LOOP THROUGH AND PERFORM ANALYSES
grps = unique(fgroup(~isnan(fgroup))); 

for i=1:numel(grps)
    
    % Create logical mask
    mask = false(numel(fgroup),1);
    mask(fgroup == grps(i)) = true; 
    mask = find(mask); % convert to indices.
    
    % Get the filenames from the data variable. Will use this to figure out
    % which data traces go where
    fnames = {data{mask,1}}; 
    
    % Create a variable to store data traces
    %   Col 1 = +1/+1
    %   Col 2 =  +1/-1
    %   Col 3 = -1/-1
    %   Col 4 = -1/+1
    D = [];
    
    % Find +1/+1
    ind = findcell(fnames, [d.tstr d.origstr d.nstr d.origstr]);
    % Quick check to make sure we only found one
    if numel(ind)~=1, error(['Found ' num2str(numel(ind)) ' instead of 1 and only 1']); end
    D = [D data{mask(ind) ,2}]; % this is the original/original data trace. Rinse and repeat for other combinations.
    
    % Find +1/-1
    ind = findcell(fnames, [d.tstr d.origstr d.nstr d.invstr]);
    % Quick check to make sure we only found one
    if numel(ind)~=1, error(['Found ' num2str(numel(ind)) ' instead of 1 and only 1']); end
    D = [D data{mask(ind) ,2}]; % this is the original/original data trace. Rinse and repeat for other combinations.
    
    % Find -1/-1
    ind = findcell(fnames, [d.tstr d.invstr d.nstr d.invstr]);
    % Quick check to make sure we only found one
    if numel(ind)~=1, error(['Found ' num2str(numel(ind)) ' instead of 1 and only 1']); end
    D = [D data{mask(ind) ,2}]; % this is the original/original data trace. Rinse and repeat for other combinations.
    
    % Find -1/+1
    ind = findcell(fnames, [d.tstr d.invstr d.nstr d.origstr]);
    % Quick check to make sure we only found one
    if numel(ind)~=1, error(['Found ' num2str(numel(ind)) ' instead of 1 and only 1']); end
    D = [D data{mask(ind) ,2}]; % this is the original/original data trace. Rinse and repeat for other combinations.
    
    %% DO ANALYSES
    
    % Find target signal
    %   This is done two ways:    
    OUT = [OUT Hagerman_getsignal(D(:,1:NCHANS), D(:,1+NCHANS:2*NCHANS), 'fsx', FS, 'fsy', FS, 'pflag', d.plot)];        
    
end % for i=1:numel(grps)