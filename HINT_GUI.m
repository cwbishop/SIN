function varargout = HINT_GUI(varargin)
% HINT_GUI MATLAB code for HINT_GUI.fig
%      HINT_GUI, by itself, creates a new HINT_GUI or raises the existing
%      singleton*.
%
%      H = HINT_GUI returns the handle to a new HINT_GUI or the handle to
%      the existing singleton*.
%
%      HINT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HINT_GUI.M with the given input arguments.
%
%      HINT_GUI('Property','Value',...) creates a new HINT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before HINT_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HINT_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
% 
% INPUTS:
%
%   'xlabel':   string, xlabel for figure. (default='Trial #')
%
%   'ylabel':   string, 'ylabel' for figure. (default='SNR (dB)')
%
%   'ntrials':  number of trials to play (sets axis information)
%
%   'score_labels': cell array, scoring labels used in scoring boxes. These
%                   default to 'correct' and 'incorrect' 
%
%   'words':    cell array, each cell is a string to score (usually a word)
%
%   'xdata':    xdata for plotting in inset axes
%
%   'ydata':    ydata for plotting in inset axes
%
%   'title':    title for figure (upper left). 
%
%   'isscored': bool array equal to the number of words in string. Each
%               element corresponds to the same element of 'words'. A true
%               value means it will be scored (scoring box visible). A
%               false value means it will not be scored (scoring box
%               invisible). (default = false for all elements)
%
% Christopher W. Bishop (with help of GUIDE)
%   University of Washington
%   5/14

% Edit the above text to modify the response to help HINT_GUI

% Last Modified by GUIDE v2.5 06-May-2014 19:19:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HINT_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @HINT_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before HINT_GUI is made visible.
function HINT_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HINT_GUI (see VARARGIN)

% Choose default command line output for HINT_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Convert parameters to structure (easier to work with)
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end % if length ...

if ~isfield(p, 'words'), p.words=[]; end % no words by default 
if ~isfield(p, 'isscored'), p.isscored=false(length(p.words),1); end % no scoring by default. 
if ~isfield(p, 'xlabel'), p.xlabel='Trial #'; end 
if ~isfield(p, 'ylabel'), p.ylabel='SNR (dB)'; end 
if ~isfield(p, 'ntrials'), p.ntrials=20; end % set to 20 by default since we'll never have more than 20
if ~isfield(p, 'score_labels'), p.score_labels={'Correct', 'Incorrect'}; end 
if ~isfield(p, 'xdata'), p.xdata=[]; end 
if ~isfield(p, 'ydata'), p.ydata=[]; end

% Misc defaults
global max_words;    % the maximum number of scorable words
global max_options;  % the maximum number of options for each word.
max_words=6;
max_options=2; 

% Error check for p.words. GUI is designed to support 6 words, so throw an
% error if we have more than that
if length(p.words) > max_words, error('Too many words'); end

% Error check for p.score_labels. Figure only supports two scoring
% categories, so throw an error if we have too many
if length(p.score_labels) > max_options, error('Too many scoring labels'); end 

% Quick check to make sure we have enough scoring information for all words
if length(p.isscored) ~= length(p.words), error('Scoring vector does not match number of words'); end 

% Create axis labels
%   Set XLabel, YLabel
set(get(handles.panel_plot, 'YLabel'), 'String', p.ylabel);
set(get(handles.panel_plot, 'XLabel'), 'String', p.xlabel);

% Change figure name (upper left corner)
set(handles.figure1, 'Name', p.title); 

%% RESET GUI
%   Reset words and scoring panels to default state (empty strings and
%   invisible scoring panels). 
for d=1:max_words
    
    % Reset word values
    set(handles.(['word' num2str(d) '_text']), 'String', '');
    
    % Set all panels to invisible
    set(handles.(['word' num2str(d) '_scoring']), 'Visible', 'off'); 
    
    % Reset option labels and values 
    for o=1:max_options
        set(handles.(['word' num2str(d) '_opt' num2str(o)]), 'String', p.score_labels{o}); 
        set(handles.(['word' num2str(d) '_opt' num2str(o)]), 'Value', 0); 
    end % o=1:max_options
    
end % d=1:max_words

% Set domain
xlim([0 p.ntrials]); 

%% ADD WORDS AND SCORING PANELS
%   Add words to figure and enable scoring panels
for n=1:length(p.words)
    
    % Add word to GUI
    set(handles.(['word' num2str(n) '_text']), 'String', p.words{n});
    
    % Add scoring panel
    %   - Recall that these are invisible by default 
    if p.isscored(n)
        set(handles.(['word' num2str(n) '_scoring']), 'Visible', 'on'); 
    end % if p.isscored(n)
    
end % for n=1:length(p.words)       

%% UPDATE PLOT
%   When plot data is provided, update the plot. This is useful for
%   visualization (and debugging). 
if ~isempty(p.xdata) && ~isempty(p.ydata)
    lineplot2d(p.xdata, p.ydata, 'marker', 'o');  
end % if ~

% UIWAIT makes HINT_GUI wait for user response (see UIRESUME)
%   Waits for user input and response. Part of flow control for this
%   HINT_modcheck_GUI.m. 
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = HINT_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Get score and response values matrices
[score, response_values]=HINT_GUI_score_responses(handles); 

varargout{2}=score; 

% Delete figure
% delete(handles.figure1); 

% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in button_next.
function button_next_Callback(hObject, eventdata, handles)
% hObject    handle to button_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Error checking
[~, ~, iserror]=HINT_GUI_score_responses(handles); 

% Resume UI.
if isequal(get(handles.figure1, 'waitstatus'), 'waiting') && ~iserror
    uiresume(handles.figure1);
end % if isequal ...

% --- Executes on button press in record_checkbox.
function record_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to record_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of record_checkbox


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

% When we close the GUI, we want to resume the user interface (ui). 
%   Code gleaned from http://blogs.mathworks.com/videos/2010/02/12/advanced-getting-an-output-from-a-guide-gui/
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else 
    delete(hObject); 
end % 

% Scoring function
function [score, response_values, iserror]=HINT_GUI_score_responses(handles)
%% DESCRIPTION:
%
%   Function to do some basic error checking and also generate scoring
%   arrays.
%
% INPUT:
%
%   handles:    handles structure passed between everything
%
% OUTPUT:
%
%   score:  scored array. Scoring index goes like this
%               -1: unscorable word (invisible scoring box)
%               0:  No option selected (we need to implement some checks to 
%                   make sure this doesn't happen).
%               1:  Option 1 selected
%               2:  Option 2 selected
%               etc. ... 
%
%               note: code only tested with two options. will need to be
%               checked thoroughly if more options are added. 
%
%   response_values:    dxo matrix, where d is the number of words, and o
%                       is the number of options available for selection.
%                       This may not be necessary (CWB 5/14), but is here
%                       until CWB can test more thoroughly. 
%
%   iserror:    bool, error flag. If set (true) then there's an error that
%               needs to be addressed.
%           
% Development:
%
%   1. Need to thoroughly test return values and response combinations. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

global max_words;
global max_options;

% Error checking
%
%   1. Make sure all scorable words have an option selected. If they do
%   not, then tell the user that he (or she) needs to select an appropriate
%   response. 
%
%   2. Make sure multiple options are not selected
%
%   3. Make sure an option is selected for each (scorable) word. 

% Initialize as unscorable 
score=ones(max_words, 1).*-1; 

% Initialize error flag
iserror=false; 

for d=1:max_words
    
    % Get the response for each option
    for o=1:max_options
        
        % Only gather responses if this is a "scored" word (meaning the
        % scoring panel is visible) 
        if isequal(get(handles.(['word' num2str(d) '_scoring']), 'Visible'), 'on')
            response_values(d, o)=get(handles.(['word' num2str(d) '_opt' num2str(o)]), 'Value');
        else
            response_values(d, o)=-1; 
        end % if isequal
    end % for o=1:max_opts
    
    % Error checking must be done when NEXT is clicked. So, we need to
    % assume errors don't make it through to the output level.
    %
    % But, just to make sure, here's a basic check to make sure we don't
    % have multiple selections or no selections 
    if numel(find(response_values(d, :)~=0)) ~= 1 && isequal(get(handles.(['word' num2str(d) '_scoring']), 'Visible'), 'on')
        errordlg(['Incorrect number of responses selected for word ' num2str(d)]); 
        iserror=true; 
        break; 
    elseif isequal(get(handles.(['word' num2str(d) '_scoring']), 'Visible'), 'on')
        % Only overwrite the '-1' place holder if the word should be
        % scored. 
        score(d)=find(response_values(d,:)==1, 1, 'first'); 
    end % if numel        
    
end % for d=1:max_words

function plot_some_data(p)
plot(p.xdata, p.ydata);