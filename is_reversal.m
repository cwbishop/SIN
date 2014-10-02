function [is_rev, nrev] = is_reversal(data, varargin)
%% DESCRIPTION:
%
%   This function takes a time series, data, and determines which points
%   are likely reversals (e.g., a reversal in the direction of change).
%   This was written and intended to be used in combination with tests like
%   the HINT (SNR-80 ...) and other adaptive algorithms that are required
%   to terminate after a specific number of reversals. 
%
% INPUT:
%
%   data:   Nx1 vector, the time series to find reversals in.
%
% Parameters:
%
%   'plot': bool, if set, then a descriptive plot is generated. If false,
%           then no plot generated. (default = false); 
%
% OUTPUT:
%
%   isrev:  Nx1 vector, bool (true/false). The element is true if that
%           specific element is a reversal. Otherwise, false.
%
%   nrev:   integer, the number of reversals in the time series. This is
%           derived directly from isrev by counting the number of true
%           elements in isrev. This additional return variable will
%           centralize the counting and make this easier to use ... or so
%           CWB thinks.
%
% Development:
%
%   None (yet)
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET PARAMETERS 
d=varargin2struct(varargin{:});

%% SET DEFAULTS

% Don't plot results by default 
if ~isfield(d, 'plot') || isempty(d.plot), d.plot = false; end

%% INITIALIZE RETURN VARIABLES
is_rev = false(size(data)); 

% The section below is rather confusing, to be honest. CWB has tried to
% comment as well as possible here, but ultimately it's still very
% confusing. Another resource worth looking into is algo_NALadaptive. That
% is where CWB first wrote the reversal tracking algorithm. Commenting and
% explanations there might be better. 

% We need to remove repeated values since these will not be informative in
% detecting reversals. However, we want to keep the LAST instance of a
% repeated value in consecutive trials - that way the reversal is assigned
% to the last trial - that's treally the "reversal" point.

% Determine in which direction the time series is moving in.
step_direction = (sign(diff(data)));

data_clean = [];

% This creates an array index (clean2orig) that can be used to mask the
% original data. When the original data are masked, only the *potential*
% reversonal points are returned. 
start_index = 1; 
clean2orig = [];
while start_index < numel(step_direction)
    
    % Focus on the next chunk of data
    tstep_direction = step_direction(start_index:end); 
    
    % Find first zero (no change)
    first_zero = find(tstep_direction == 0, 1, 'first'); 
    
    % If there are NOT any zeros repeats, then set first_zero to the end of
    % the vector + 1. This will force the indexing below to behave properly
    if isempty(first_zero)
%         first_zero = numel(data) + 1; 
        clean2orig = [clean2orig; [start_index : numel(data)]];
        break
    end % 
    
    % Add beginning samples to data
    clean2orig = [clean2orig; [start_index : start_index + first_zero - 2]'];
    
    % Truncate data 
    tstep_direction = tstep_direction(first_zero:end);
    
    % Find last zero (no change)
    last_zero = find(tstep_direction ~= 0, 1, 'first'); 
    
    % Add last_zero to clean2orig
    clean2orig = [clean2orig; last_zero + first_zero + start_index - 2]; %#ok<*AGROW>
    
    start_index = last_zero + first_zero + start_index - 1; 
end % while

%% LOOK AT POTENTIAL REVERSAL POINTS
data_clean = data(clean2orig);

% This complicated piece of code here is the reversal detection algo.
is_rev(clean2orig(find(diff(sign(diff(data_clean)))~=0)+1')) = true;

% Count the number of reversals 
nrev = numel(find(is_rev)); 

%% VISUALIZATION PLOTS
if d.plot
         
    lineplot2d(1:numel(data), data, ...
        'xlabel',   'Data Point', ...
        'ylabel',   'Data Value', ...
        'title',    '', ...
        'grid',     'on', ...
        'linewidth',    2, ...
        'color',    'k', ...
        'marker',   'o', ...
        'fignum',   gcf); 
    
    hold on
    plot(find(is_rev), data(is_rev), 'ro', 'linewidth', 2)
        
    legend({'Data Trace', 'Reversals'}, 'location', 'best')
    
end % if d.plot 
% Are these points actually a reversal?

%
% while ~isempty(step_direction)
%     
%     % Find the first instance when the step direction is 0. We'll trim the
%     % data up to that point, then figure out if there are consecutive
%     % zeros.
%     first_repeat = find(step_direction == 0, 1, 'first');   
%     
%     % Crop data.
%     step_direction = step_direction(first_repeat:end);     
%     
%     % See if this is a string of repeated values
%     last_repeat = find(step_direction ~= 0, 1, 'first') + first_repeat - 1; 
%     
%     % If this is not a string of repeated values, then assume the first
%     % element is the first and last repeat. 
%     if isempty(last_repeat)
%         last_repeat = first_repeat; 
%     end % if isempty(last_repeat); 
%     
%     % Add the data we're about to crop out as potential reversal points.
%     % Intuitively, these are non-repeated values.
%     if isempty(clean2orig)
%         clean2orig = [clean2orig; [1:first_repeat - 1]'];
%     elseif ~isempty(last_repeat) && last_repeat ~= 1 
%         clean2orig = [clean2orig; [clean2orig(end)+1:clean2orig(end)+ first_repeat ]'];    
%     end % if isempty(clean2orig)
%     
%     % Break out of while loop if there aren't any zeros to begin with (or
%     % remaining.
%     if isempty(first_repeat)
%         break;
%     end % if isempty(ind)
%     
%     
%     
%     % This is the data point we want to flag as a reversal if there's a
%     % sign change after this block of repeated values.
% %     data_clean(end+1,1) = data(last_repeat + numel(data) - numel(step_direction)); 
% %     
%     % Update clean2orig. This will help us map the clean data back to the
%     % original data trace for labeling purposes later. 
% %     if ~exist('clean2orig', 'var')
% %         clean2orig = [clean2orig; first_repeat + last_repeat];
% %     else
%     if n == 1
%         clean2orig = [clean2orig; first_repeat + last_repeat];
%     elseif first_repeat == 1 && last_repeat == 1
%         clean2orig = [clean2orig; clean2orig(end) + 1];
%     else
%         clean2orig = [clean2orig; clean2orig(end) + first_repeat + last_repeat + 1];
%     end %
% 
%    % Truncate step_direction
%     step_direction = step_direction(last_repeat:end); 
%     
%     % Increment counter
%     n = n + 1;
% end % while 

% We are only interested in non-zero changes, so create a mask. The mask
% will later help us identify precisely which trials are reversals and
% which are not. Without this mask, we could not reference the data
% correctly.
% mask = step_direction ~= 0;


% The reversal mask flags the reversals in the data, but they do not align
% properly with the original time series. Data are reprojected to the
% original time series below. The indices here tell us which non-zero step
% in the original time series is a reversal. We removed zero step sized
% changes, however, so the indices don't align correctly. We will use the
% "mask" variable above to remap rev_mask below. 
% rev_mask = find(diff(step_direction ~= 0)); 
% 
% % Reproject back into original data space
% for i=1:numel(rev_mask)
%     
%     % Find the first Nth trues in mask. 
%     % mask2data stores the data point in the original time series that
%     % is a reversal
%     mask2data = find(mask, rev_mask(i), 'first');
%     
%     % The last true is all we're interested in. 
%     mask2data = mask2data(end); 
%     
%     % Must increment mask2data by one since we did a double diff above.
%     mask2data = mask2data + 1;
%     
%     % Set reversal as true for this trial
%     is_rev(mask2data) = true;
%     
% end % for i=1:nume(rev_mask)
% 
% %% COUNT THE NUMBER OF REVERSALS
% nrev = numel(find(is_rev)); 