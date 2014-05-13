function [X_align, Y_align, lags]=align_timeseries(X, Y, routine, varargin)
%% DESCRIPTION:
%
%   Function to align time series using one of several realignment
%   strategies.
%
%   If the signal in Y occurs before the signal in X, then Y is delayed to
%   match Y. 
%
%   If the signal in X occurs before the signal in Y, then X is delayed to
%   match X.
%
%   Both time series are zero padded after realignment (either prepended
%   zeros or appended zeros depending on the direction of the shift) so
%   signal lengths match after realignment. 
%
%   Note: This has only been tested with a single time series in Y, but
%         should be capable of aligning multiple signals. 
%
% INPUT:
%
%   X:  reference time series. Each data series in Y is realigned to X.
%       HOWEVER, if the signal in Y is delayed relative to X (as is
%       typically the case with recorded sound), then X is temporally
%       shifted to match Y. This must be a single data series (no 
%       multichannel data). Supports WAV and double/single formats. 
%
%   Y:  Data series to realign to reference series X. Y be a cell array of
%       file names to WAV files or a double matrix where each column of Y
%       corresponds to a time series. 
%           Note:   If the sampling rate of Y does not match the sampling
%                   rate of X, then Y is resampled to match the sampling
%                   rate of X. 
%
%   routine:  realignment routine to use. Other options can be easily
%               added.
%                   'xcorr':    maximum cross-correlation used for
%                               realignment.
%                   'threshold':    data series aligned by finding first
%                                   time point that meets or exceeds a
%                                   specified threshold. If threshold is
%                                   desired, an additional paramter must be
%                                   specified. (see Parameters below)
% Parameters:
%
%   'pflag':    integer, flag to generate plots.
%                   0:  no plots generated (default)
%                   1:  time courses are plotted before and after
%                       realignment. 
%
%   'thresh_abs':   absolute threshold value for realignment. The routine
%                   will search for the first sample that meets or exceeds
%                   this value in X and Y and use that information to
%                   realign the two time series. Note that the absolute
%                   value of the time series is used in this case, so
%                   values deviating by thresh_abs (either positive or
%                   negative) may contribute to realignment. 
%
%   'yoke': bool, apply same temporal shift to all time series. This
%           ensures that the relative delays between time series in Y
%           (relative to X) are maintained. 
%
%   'fsx':  double, sampling rate of X time series. This only needs to be
%           specified if X is a double matrix.
%
%   'fsy':  double, sampling rate of Y time series. This only needs to be
%           specified if Y is a double matrix. 
%
% OUTPUT:
%   
%   X_align:    aligned X series. Each column of X_align is realigned 
%               relative to the same column of Y_align. Since variable lags 
%               are applied and the direction of the shift may be different 
%               for each time series pair, it made more sense to CWB to 
%               create pairs and work from there. 
%
%   Y_align:    aligned Y series. Each column of Y_align is realigned 
%               relative to the corresponding colum of X_align. 
%
% Christopher W. Bishop
%   University of Washington
%   4/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

% Place routine in the parameter structure.
p.routine=routine; 
clear routine;

%% DEFAULTS
%   Default values for realignment 
if ~isfield(p, 'fsx'), p.fsx=[]; end 
if ~isfield(p, 'fsy'), p.fsy=[]; end
if ~isfield(p, 'yoke') || isempty(p.yoke), p.yoke=false; end 
if ~isfield(p, 'pflag') || isempty(p.pflag), p.pflag=0; end % no plots by default 

%% LOAD DATA
% For X series, only allow a single time series as a reference. 
% Y series can have an infinite number of time series. 
t.maxts=1; t.fs=p.fsx;
[X, fsx]=AA_loaddata(X, t); 
clear t;
t.fs=p.fsy; 
[Y, fsy]=AA_loaddata(Y, t); 

%% CHECK SAMPLING RATES
if (isfield(p, 'fsx') && isempty(p.fsx)) && ~isempty(fsx)
    p.fsx=fsx; 
end % if (isfield ..

if (isfield(p, 'fsy') && isempty(p.fsy)) && ~isempty(fsy)
    p.fsy=fsy; 
end % if (isfield ..

%% RESAMPLE
%   Resample time series so they match X. 
Y=resample(Y, p.fsx, p.fsy);

%% PERFORM REALIGNMENT
%   A realignment parameter is estimtated for each time series in Y such
%   that, when applied, the time series in Y should be maximally aligned
%   with X. 
lags=nan(size(Y,2),1);

for i=1:size(Y,2)
    
    switch p.routine
    
        case {'xcorr'}
            % Use cross correlation
            corr_xy=(xcorr(X, Y(:,i), 'none')); 
            
            % Find maximum cross correlation
            mcxy=max(abs(corr_xy)); 
            
            % Create logical mask
            mask=abs(corr_xy)==mcxy; 
            
            % Error check in the event of multiple equivalent alignements
            if numel(corr_xy(mask))>1
                error('Ambiguous alignment'); 
            end % numel 
            
            % Define lag            
            lags(i,1)=find(mask==1, 1, 'first'); 
            
            % Adjust to center bin (0 lag)
            lags(i,1)=lags(i,1)-(length(corr_xy)+1)/2;
            
        case {'threshold'}
            
            % Threshold checks
            %   Can be expanded to include other threshold types, but
            %   thresh_abs is the most intuitive in the context of Hagerman
            %   recordings and most other situations CWB is familiar with. 
            if ~isfield(p, 'thresh_abs') || isempty(p.thresh_abs)
                error('No threshold specified'); 
            end % ~isfield(p, 'thresh_abs') || ...            
            
            lags(i,1)=find(abs(X)>p.thresh_abs, 1, 'first') - find(abs(Y(:,i))>p.thresh_abs, 1, 'first');
        otherwise
            error('Unknown routine'); 
    end % switch p.routine
    
end % for i=1:size(Y,2)

%% REALIGN Y  
%   Realignment is done in a separately to allow 'yoking' of signals.
%       Yoking not tested well. 
if p.yoke
    % First, find the minimal shift (either positive or negative). Apply
    % this shift to all time series.
    mask=abs(lags)==min(abs(lags)); 
    
    % Reset all lags to this lag. 
    lags(:,:)=lags(mask); 
end 

% Now, apply realignment to all data series.
%   Preallocate X_align and Y_align
warning('Should these be nan??'); 
X_align=zeros(size(X,1)+abs(min(lags)),size(X,2));
Y_align=zeros(size(Y,1)+abs(max(lags)),size(Y,2)); 

for i=1:size(Y,2)
    if lags(i,1)>0
        % Positive lag means Y happens BEFORE X. 
        ypad=zeros(size(Y_align,1) - (abs(lags(i,1)) + size(Y,1)), 1);
        xpad=zeros(size(X_align,1) - size(X,1), 1);
        Y_align(:,i)=[zeros(lags(i,1), 1); Y(:, i); ypad ]; 
        X_align(:,i)=[X; xpad];
    elseif lags(i,1)<0
        % Negative lag means Y happens AFTER X.
        xpad=zeros(size(X_align,1) - (abs(lags(i,1)) + size(X,1)), 1);
        ypad=zeros(size(Y_align,1) - size(Y,1), 1);
        X_align(:,i)=[zeros(abs(lags(i,1)), 1); X; xpad]; 
        Y_align(:,i)=[Y(:,i); ypad];
    end % if lags
end % for i=1:size(Y,2)

%% RESIZE MATRICES
% Confirm that X and Y are the same size. If they are not, then make it so.
if size(X_align,1) > size(Y_align,1)
    Y_align=[Y_align; zeros(size(X_align,1)-size(Y_align,1),size(Y_align,2))];
elseif size(Y_align,1)>size(X_align,1)
    X_align=[X_align; zeros(size(Y_align,1)-size(X_align,1),size(X_align, 2))];
end % if size ...

%% PLOTTING
%   Generate plots for visual confirmation of realignment
if p.pflag>0
    
    % Get Labels for Y series
    %   Used to creat figure titles below. 
    [~, ~, LABELS]=AA_loaddata(ones(size(Y,2), 10), 'fs', p.fsx);
    
    % Generate a single plot for each realigned signal pair
    for i=1:size(Y_align,2)
        % Plot X data
        T=0:1/p.fsx:(size(X,1)-1)/p.fsx;     
        T=AA_loaddata(T, 'fs', p.fsx);  % set correct dimensions
        lineplot2d(T, X, 'linewidth', 3, 'xlabel', 'Time (s)', 'ylabel', 'Units', 'title', 'Aligned Time Series', 'linestyle', '--'); % opens a new figure 
    
        % Plot Y (orig) data
        T=0:1/p.fsx:(size(Y,1)-1)/p.fsx;     
        T=AA_loaddata(T, 'fs', p.fsx);  % set correct dimensions
                                        % data resample to fsx, so keep
                                        % sampling rate the same.
        lineplot2d(T, Y(:,i), 'linewidth', 3, 'xlabel', 'Time (s)', 'ylabel', 'Units', 'title', 'Aligned Time Series', 'linestyle', '--', 'startat', 1, 'fignum', gcf); % opens a new figure 
                                        
        % Plot Y data
        T=0:1/p.fsx:(size(Y_align,1)-1)/p.fsx; 
        lineplot2d(T, [X_align(:,i) Y_align(:,i)], 'legend', {{'X (orig)' 'Y (orig)' 'X (aligned)'  'Y (aligned)'}}, 'linewidth', 1.5, 'xlabel', 'Time (s)', 'ylabel', 'Units', 'title', LABELS{i}, 'fignum', gcf, 'grid', 'on', 'startat', 2, 'legend_position', 'EastOutside'); % opens a new figure         
        
    end % for i=1:size(Y_align, 2)
    
end % p.pflag

