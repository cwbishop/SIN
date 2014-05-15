function varargout = SIN_GUI(varargin)
% SIN_GUI MATLAB code for SIN_GUI.fig
%      SIN_GUI, by itself, creates a new SIN_GUI or raises the existing
%      singleton*.
%
%      H = SIN_GUI returns the handle to a new SIN_GUI or the handle to
%      the existing singleton*.
%
%      SIN_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIN_GUI.M with the given input arguments.
%
%      SIN_GUI('Property','Value',...) creates a new SIN_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SIN_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SIN_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
%
% Development:
%
%   1) Refresh list popup in a smarter way. Possibly incorporate it into
%   refresh_popups. 
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SIN_GUI

% Last Modified by GUIDE v2.5 15-May-2014 06:49:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SIN_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SIN_GUI_OutputFcn, ...
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


% --- Executes just before SIN_GUI is made visible.
function SIN_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SIN_GUI (see VARARGIN)

% Choose default command line output for SIN_GUI
handles.output = hObject;

% Load defaults, store them as GUI data (makes it easier for other
% functions to have access to defaults without having to deal with passing
% variables or globals)
%
% Motivation for this approach from :
%       http://www.matlabtips.com/handle-the-handles-in-guidata/
handles.SIN_defaults=SIN_defaults; 

% Update handles structure
guidata(hObject, handles);

% Populate popup menus
refresh_popups(hObject, eventdata, handles); 

% UIWAIT makes SIN_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SIN_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in test_popup.
function test_popup_Callback(hObject, eventdata, handles)
% hObject    handle to test_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns test_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from test_popup

% Get SIN_defaults from handles structure
%   This field is populated in the opening function.
d=handles.SIN_defaults;

% Now, get popup menu information
val=get(handles.test_popup, 'Value'); 
testID=get(handles.test_popup, 'String');

% The first option is just for 'Select Test' string. We don't need to do
% anything for this 
if val ~= 1
    [list_dir, list_names, wavfiles]=SIN_stiminfo(testID{val}, d);
end % if val ~= 1
    
% Now, populate List selection if there's list information available
if ~isempty(list_names)
    set(handles.list_popup, 'String', list_names)
end % ~isempty(list_names) ...

% --- Executes during object creation, after setting all properties.
function test_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to test_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in run_test_button.
function run_test_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_test_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% See which test is selected in the popup menu

% --- Executes on selection change in calibration_popup.
function calibration_popup_Callback(hObject, eventdata, handles)
% hObject    handle to calibration_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns calibration_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from calibration_popup


% --- Executes during object creation, after setting all properties.
function calibration_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calibration_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in start_calibration_button.
function start_calibration_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_calibration_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in subject_popup.
function subject_popup_Callback(hObject, eventdata, handles)
% hObject    handle to subject_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subject_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from subject_popup


% --- Executes during object creation, after setting all properties.
function subject_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subject_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in register_subject_button.
function register_subject_button_Callback(hObject, eventdata, handles)
% hObject    handle to register_subject_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Grab defaults from handles structure
d=handles.SIN_defaults; 

% Try registering subject
[status, err]=SIN_register_subject(get(handles.subjectid, 'String'), 'register_tasks', {{'create'}}, 'subjectID_regexp', d.subjectID_regexp); 

% Clear subject ID field
set(handles.subjectid, 'String', ''); 

% Post error message if we encounter one. 
post_feedback(hObject, eventdata, handles, err);
    
% Repopulate popup menus
refresh_popups(hObject, eventdata, handles);

function refresh_popups(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   Function to populate (or update) list items in popup menus
%
% Christopher W. Bishop
%   University of Washington 
%   5/14

% POPULATE POP-UP MENUS
%
%   Assumes SIN_GUI is launched from the top-level directory. 
%

% Query existing subjects
%   Query based on existing directories. If the directories don't exist,
%   then we have to assume that no subject data has been collected. 
%
%   Code modified from:
%       http://stackoverflow.com/questions/8748976/list-the-subfolders-in-a-folder-matlab-only-subfolders-not-files
subject_id = dir(fullfile(pwd, 'subject_data')); 
subject_id = {subject_id((vertcat(subject_id.isdir))).name};
subject_id(ismember(subject_id,{'.','..'})) = [];

% Populate subject popup
set(handles.subject_popup, 'String', [{'Select Subject'} subject_id])

% Query calibration files
cal_files = dir(fullfile(pwd, 'calibration', '*.mat')); 
cal_files = {cal_files(:).name};

% Populate calibration popup
set(handles.calibration_popup, 'String', [{'Select File'} cal_files]);

% Populate test list
d=handles.SIN_defaults; 
set(handles.test_popup, 'String', [{'Select Test'} {d.testlist.name}]); 

function subjectid_Callback(hObject, eventdata, handles)
% hObject    handle to subjectid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subjectid as text
%        str2double(get(hObject,'String')) returns contents of subjectid as a double


% --- Executes during object creation, after setting all properties.
function subjectid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjectid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function post_feedback(hObject, eventdata, handles, str, status, varargin)
%% DESCRIPTION:
%
%   Function to post text to the feedback terminal (bottom of GUI
%   currently).
%
% INPUT:
%
%   hObject:    see other functions
%   eventdata:  nothing useful (yet)
%   handles:    handle structure
%   str:    string to post to feedback terminal
%   status: integer value, determines type of text feedback to provide.
%               0:  An error message (listed in red)
%               1:  Success message (listed in green)
%               ... more to come ...
%
% OUTPUT:
%
%   None (yet)
%
% Development:
%
%   XXX None (yet) XXX
%
% Christopher W. Bishop
%   University of Washington 
%   5/14

% Set feedback color
switch status
    case {0}
        col='r';
    case {1}
        col='g';
    otherwise
        col='k';
end % switch/otherwise
set(handles.feedback_text, 'ForegroundColor', color2colormap({col}));

% Set string
set(handles.feedback_text, 'String', str); 


% --- Executes on selection change in list_popup.
function list_popup_Callback(hObject, eventdata, handles)
% hObject    handle to list_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_popup


% --- Executes during object creation, after setting all properties.
function list_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
