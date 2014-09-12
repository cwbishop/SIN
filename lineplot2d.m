function d=lineplot2d(X, Y, varargin)
%% DESCRIPTION:
%
%   Function to create two-dimensional line plots complete with error bars
%   (if specified). 
%
%   CWB found that he was recycling a lot of code to create similar line
%   plots in various functions for project AA, so decided to centralize the
%   plotting routines. 
%
% INPUT:
%
%   X:  double matrix, column vector of domain values (e.g., time or
%       frequency). 
%
%   Y:  CxNxTxS or NxTxS matrix, where C is the number of groups of series
%       (typically the number of channels), N is the number of data points
%       (typically time points or frequency bins), T is the number of data
%       series (typically number of bins in ERP structures, but can be
%       anything), and S is the number of measures (typically subjects).
%
%
%   Additional Parameters:
%
%       'xlabel':   string, x-axis label
%       'ylabel':   string, y-axis label
%       'title':    string or cell array. If a string, then all C figures
%                   will have the same title. Similiarly, if a single cell,
%                   then all C figures will have the same title. Otherwise,
%                   if title is a C-element cell array, then each figure
%                   will have its own title.
%       'legend':   cell array corresponding to the T data series in Y.
%       'xlim':     two-element double array, [min max] of domain. 
%       'ylim':     two-element double array, [min max] of range. 
%       'sem':      double value, multiple of standard error of the mean
%                   (SEM) to plot with error bars. (uses ciplot.m). 
%       'grid':     turn plot grid on or off. ('on' | 'off'; default='on');
%       'linewidth':    line width
%       'color':    color (if user wants to specify the color). 
%       'linestyle':    line style
%       'opacity':  opacity of error (SEM) shading. 
%       'startat':  integer, which color index to start with. This is
%                   useful when multiple calls are made to lineplot2d, but
%                   the user wants a unique color choice for each line
%                   plotted. (default=0)
%       'fignum':   figure number to plot data on. Useful when trying to
%                   plot data on the same.
%       'legend_position':  string, legend position (default='best'). See
%                           doc legend for more details on legend position
%                           parameters. 
%       'maker':    marker to use for plots
%       
%   Development notes:
%       Add options to modify common plotting parameters we use. 
%
% Christopher W. Bishop
%   University of Washington
%   3/14

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

%% DEFAULTS
%   Set default plotting parameters
d=struct( 'xlabel', {''}, ...
    'ylabel', {''}, ...
    'title', {''}, ...
    'legend', {{''}}, ...
    'xlim', [min(min(X)) max(max(X))], ... % tight x-axis
    'ylim', [max(max(abs(Y)))*-1 max(max(abs(Y)))], ... % symmetric y-axis
    'sem', 0, ...
    'grid', 'on', ...
    'linewidth', 1.5, ...
    'color', [], ...
    'linestyle', [], ...    
    'opacity', 0.15, ...
    'fignum', max(findobj('type', 'figure'))+1, ...
    'startat', 0, ...
    'legend_position', 'best'); 

%% USER DEFINED VALUES
%   User specified inputs 
flds=fieldnames(p);
for i=1:length(flds)
    d.(flds{i})=p.(flds{i}); 
end % i=1:length(flds)

%% MASSAGE Y DATA
%   Need to have consistent data dimensions for plotting
if ndims(Y)<4
    y(1,:,:,:)=Y; 
end % if ndims(Y)<4

% Reassign
Y=y; 
clear y; 

%% GET LINE TRACE COLORS
if ~isempty(d.color)
    for t=1:size(Y,3)+d.startat % also create for offset start positions
        colorDef{t}=d.color; 
%         styleDef{t}='-';
    end % for t=1:size(Y,3)
else
    % Otherwise go with default coloring scheme from ERPLAB
    [colorDef, ~]=erplab_linespec(size(Y,3)+d.startat);
end % ~isempty(d.color)

% Set linestyle information
if ~isempty(d.linestyle)
    for t=1:size(Y,3)+d.startat % also create for offset start positions 
        styleDef{t}=d.linestyle; 
    end % for t=1:size(Y,3)    
else
    [~, styleDef]=erplab_linespec(size(Y,3)+d.startat); 
end % if ~isempty(d.linestyle)

%% MASSAGE TITLE
%   Need to get title into appropriate format (a cell)

% Convert string to cell
if isa(d.title, 'char')
    d.title={d.title};
end % if isa ...

% Now make sure we have a title for all C dimensions
if numel(d.title)==1 && size(Y,1)>1
    
    % Copy title over
    for c=1:size(Y,1)
        ttl{c}=d.title;
    end % 
    
    % Reassign
    d.title=ttl;
    
end % numel(d.title)==1 ...

%% MASSAGE LEGEND
%   Make sure we have legend entries for each data series
%       Should we allow users to turn the legend off altogether? Probably.
% if isempty(d.legend{1})
%     for t=1:size(Y,3)
%         leg{t}=['Series (' num2str(t) ')'];            
%     end % for t=1:size(Y,3)
%     
%     % Reassign
%     d.legend=leg; 
% end % isempty(d.legend{1}

%% PLOT ROUTINE
% Loop through each group of data series
    
% First, plot the error bars.
%   Yes, I know I'm looping through my data twice - it makes my life
%   easier in the long run. Don't judge me.
for c=1:size(Y,1)        
           
    % Store handle for figure.
    %   Alternatively, gra
    if isempty(d.fignum)
        h(c)=figure; 
    elseif c==1
        h(c)=d.fignum;
    else
        h(c)=figure; 
    end % if isempty(d.fignum) 
    
    % Hold figure, so we can plot all data traces
    hold on
    
    for t=1:size(Y,3) 
        
        % Grab correct figure
        %   CWB added a try statement here because this fails when grabbing
        %   the axes from a GUIDE generated figure (tested with
        %   HINT_GUI.m). 
        try
            figure(h(c)); 
        catch
        end % try/catch 
            
        
        % Grab raw data
        tdata=squeeze(Y(c,:,t,:));
            
        % Plot standard error if user asks for it
        %   But only if there are at least two subjects
        %   Use size(Y,4) instead of size(tdata,2) because the latter
        %   doesn't work with a single subject. 
        if d.sem~=0 && size(Y,4)>1
            % Compute +/-NSEM SEM
            U=mean(tdata,2) + sem(tdata)*d.sem; 
            L=mean(tdata,2) - sem(tdata)*d.sem; 
            ciplot(L, U, f, colorDef{t}, d.opacity);             
        end % if d.sem~=0            
    end % b=1:size(Y,3)
end % c=1:size(Y,1)
    
% Second, plot the mean data
for c=1:size(Y,1)
    % Get back to the correct figure
    %   Again, CWB added a try catch statement here because this call fails
    %   with GUIDE generated figures.
    try
        figure(h(c)); 
    catch
    end % try/catch 
    
    hold on
    for t=1:size(Y,3)
         
        % Grab raw data
        tdata=squeeze(Y(c,:,t,:));
        
        % Find mean across subjects
        %   Only take the mean if there are more than one subject
        if size(Y,4)>1
            tdata=mean(tdata,2);                            
        end % if size(Y,4)>1
                      
        % Plot mean series for this channel/bin
        %   Added conditional statement to incorporate marker
        %   specifications. CWB hates this fix, but he's tired. 
        if ~isfield(d, 'marker')
            plot(X, tdata, 'Color', colorDef{t+d.startat}, 'LineStyle', styleDef{t+d.startat}, 'linewidth', d.linewidth);
        else
            plot(X, tdata, 'Color', colorDef{t+d.startat}, 'LineStyle', styleDef{t+d.startat}, 'linewidth', d.linewidth, 'Marker', d.marker);
        end % if isfield
          
    end % b=1:size(Y,3)
      
    %% MARKUP FIGURE
    
    % Set axis limits
    txlim=get(gca, 'XLim');
    if ~isempty(d.xlim) && (d.xlim(1) < txlim(1) || d.xlim(2) > txlim(2))
        xlim(d.xlim); 
    end % if ~isempty ...
    
    tylim=get(gca, 'YLim');
    if ~isempty(d.ylim) && (d.ylim(1) < tylim(1) || d.ylim(2) > tylim(2))
        ylim(d.ylim);
    end % if ~isempty(d.ylim)
    
    % Set title and axis labels
    %   Only set if values are not empty. 
    if ~isempty(title(d.title{c})), title(d.title{c}); end % if ~isempty(title ...
    if ~isempty(d.xlabel), xlabel(d.xlabel); end 
    if ~isempty(d.ylabel), ylabel(d.ylabel); end
    
    % Add legend
    %   Again, only add if it's not empty.
    %       Kind of a hack here that will throw a shoe if the user wants
    %       the first entry to be blank, but others to be labeled. A work
    %       around is the set the first label to ' ' (note the space). This
    %       will achieve the user's intent. 
    if ~isempty(d.legend{1}), legend(d.legend, 'location', d.legend_position); end 
    
    % Turn grid on
    %   Have to set parameter fields directly rather than calling "grid".
    %   Calling grid repeatedly toggles the grid on or off. 
    if strcmpi(d.grid, 'on');
        set(gca, 'XGrid', 'on');
        set(gca, 'YGrid', 'on'); 
    end % grid    
    
end % c=1:size(Y,1)
