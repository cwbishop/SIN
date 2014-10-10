function varargout = Selection_GUI(varargin)
% SELECTION_GUI MATLAB code for Selection_GUI.fig
%      SELECTION_GUI, by itself, creates a new SELECTION_GUI or raises the existing
%      singleton*.
%
%      H = SELECTION_GUI returns the handle to a new SELECTION_GUI or the handle to
%      the existing singleton*.
%
%      SELECTION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECTION_GUI.M with the given input arguments.
%
%      SELECTION_GUI('Property','Value',...) creates a new SELECTION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Selection_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Selection_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Selection_GUI

% Last Modified by GUIDE v2.5 01-Oct-2014 11:17:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Selection_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Selection_GUI_OutputFcn, ...
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


% --- Executes just before Selection_GUI is made visible.
function Selection_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Selection_GUI (see VARARGIN)

% Get command line inputs
d=varargin2struct(varargin{:});

% Set title
if isfield(d, 'title')
    set(handles.figure1, 'Name', d.title); 
end % if isfield

% Set prompt
if isfield(d, 'prompt')
    set(handles.prompt_text, 'String', d.prompt);    
end % if prompt

% Set the maximum number of selections
if isfield(d, 'max_selections')
    
    if d.max_selections == -1
        set(handles.options_listbox, 'Max', numel(d.description))
    else
        set(handles.options_listbox, 'Max', d.max_selections)
    end % if d.max_selections == -1
    
end % 

% Choose default command line output for Selection_GUI
handles.output = hObject;

% Add description to handles
handles.description = d.description; 

% Update handles structure
guidata(hObject, handles);

% Populate list box and text field
refresh_popup(hObject, eventdata, handles, varargin); 

% UIWAIT makes Selection_GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = Selection_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.selection; 
varargout{2} = handles.output; 

% varargout{1} = handles.output;
% varargout{1} = handles; % return full handles structure


% --- Executes on selection change in options_listbox.
function options_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to options_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns options_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from options_listbox
refresh_popup(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function options_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to options_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in confirm_button.
function confirm_button_Callback(hObject, eventdata, handles)
% hObject    handle to confirm_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Resume after selection made 
uiresume(handles.figure1); 

function refresh_popup(hObject, eventdata, handles, varargin)
%% DESCRIPTION:
%
%   Updates fields and the like based on user selection.
%
% Christopher W Bishop
%   University of Washington
%   10/14

% Create simple options cell array
opts = {};
for i=1:numel(handles.description)
    opts{i} = num2str(i);
end % end 

% Populate listbox field
set(handles.options_listbox, 'string', opts); 

% Find selection
contents = cellstr(get(handles.options_listbox,'String'));
selection = get(handles.options_listbox,'Value');
% selection = contents{get(handles.options_listbox,'Value')};

% Update description based on selection
% set(handles.description_text, 'String', handles.description{selection}); 
description = vertcat({handles.description{selection}}');
description = vertcat(description{:});
set(handles.description_text, 'String', description); 

% Place selection in handles structure
handles.selection = selection;

% Update handles structure
guidata(hObject, handles);
