function varargout = runSIN(varargin)
% runSIN MATLAB code for runSIN.fig
%      runSIN, by itself, creates a new runSIN or raises the existing
%      singleton*.
%
%      H = runSIN returns the handle to a new runSIN or the handle to
%      the existing singleton*.
%
%      runSIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in runSIN.M with the given input arguments.
%
%      runSIN('Property','Value',...) creates a new runSIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before runSIN_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to runSIN_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
%
% Parameters:
%
%   XXX
%
% Development:
%
%   1) Add subject and calibration validation to run_test callback. Need to
%   make sure we have a valid subject ID selected, etc. 
%
%   2) Once tests have started, lock subject ID.
%
%   3) Once tests have started, lock calibration file. 
%
%   4) Validation of selected options before launching SIN_runTest. Make
%   sure it's a valid subject, test, stimulus list, the test hasn't already
%   been run, etc. 
%
%   5) Wavfile selection and validation has a bit of a bug in it. It
%   requires at least two files to be selected or the validation fails.
%   There are certainly circumstances that require only a single file to be
%   played (e.g., ANL). So this needs to be addressed, but not sure how to
%   do it at present. 
%
%   6) Need to add a calibration validation step. Make sure the selected
%   calibration file is up to snuff before we run anything. 
%
%   7) Remove list selection. This needs to be automated. Convenient to
%   allow list selection for testing purposes, of course. Maybe just render
%   this invisible for the final release?
%
%   8) Remove calibration panel from GUI. CWB has rethought this and
%   calibration procedures will need to be applied well in advance of
%   running a specific test. Calibration files will need to be
%   automatically selected. 
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help runSIN

% Last Modified by GUIDE v2.5 19-Jun-2014 12:42:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @runSIN_OpeningFcn, ...
                   'gui_OutputFcn',  @runSIN_OutputFcn, ...
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


% --- Executes just before runSIN is made visible.
function runSIN_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to runSIN (see VARARGIN)

% Choose default command line output for runSIN
handles.output = hObject;

%% GET ADDITIONAL PARAMTERS
%   o is a structure with additional options set by user
o=varargin2struct(varargin{:}); 

% Load defaults, store them as GUI data (makes it easier for other
% functions to have access to defaults without having to deal with passing
% variables or globals)
%
% Motivation for this approach from :
%       http://www.matlabtips.com/handle-the-handles-in-guidata/
% if isfield(o, 'defaults')
%     handles.SIN_defaults=o.defaults;
%     clear o; 
% else
%     handles.SIN_defaults=SIN_defaults; 
% end % if isfield(o.defaults)

% Get a testlist
handles.testlist = SIN_TestSetup('testlist'); 

% Update handles structure
guidata(hObject, handles);

% Populate popup menus
refresh_popups(hObject, eventdata, handles); 

% UIWAIT makes runSIN wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = runSIN_OutputFcn(hObject, eventdata, handles) 
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

% Refresh popup information
refresh_popups(hObject, eventdata, handles);


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

% Get testID
contents = cellstr(get(handles.test_popup,'String'));
testID = contents{get(handles.test_popup,'Value')};

% Get SubjectID
contents = cellstr(get(handles.subject_popup,'String'));
subjectID = contents{get(handles.subject_popup,'Value')};

% Get test options from SIN_TestSetup
opts = SIN_TestSetup(testID, subjectID); 

% Run the test
%   - Playlist automatically handled by SIN_getPlaylist (Called from
%   SIN_runTest). 
SIN_runTest(opts); 
% % Get wavfiles from GUI handle
% wavfiles=handles.wavfiles; 
% 
% % Get test selection
% test_val = get(handles.test_popup, 'Value'); 
% testID = get(handles.test_popup, 'String');
% 
% % Get subject selection
% subjectID = get(handles.subject_popup, 'String');
% sub_val = get(handles.subject_popup, 'Value'); 
% 
% % Get list information
% list = get(handles.list_popup, 'String');
% list_val = get(handles.list_popup, 'Value'); 
% if ischar(list), list={list}; end % convert to cell. Makes list check easier. 
% 
% % Validate list selection
% if test_val ==1
%     post_feedback(hObject, eventdata, handles, 'Error: Invalid Test', false);
%     return
% else 
%     post_feedback(hObject, eventdata, handles, 'Valid test selected', true);
% end 
% 
% % Subject validation
% if sub_val==1
%     post_feedback(hObject, eventdata, handles, 'Error: Invalid Subject', false);
%     return;
% else
%     post_feedback(hObject, eventdata, handles, 'Valid subject selected', true);
% end % if sub_val
% 
% % Validate list selection
% if list_val==1 && numel(list)>1
%     % If lists are avaiable but we haven't selected one, then throw a shoe.
%     post_feedback(hObject, eventdata, handles, 'Error: Invalid List', false);
%     return;
% elseif numel(list)>1
%     post_feedback(hObject, eventdata, handles, 'Valid list selected', true);
% else
%     post_feedback(hObject, eventdata, handles, 'No list available', []); 
% end % if sub_val

% XXX Calibration check XXX

% XXX Play list check XXX

% % Launch the appropriate test
% %   Only launch test if the following conditions are met
% %       1. A test is selected
% %       2. Some wav files are selected
% %       3. A subject is selected.
% if list_val ~= 1 && length(wavfiles)>1 
%     
%     % If there's a list selected, then present those sounds
%     % Run the first cell array in wavfiles
%     SIN_runTest(testID{test_val}, ...
%         subjectID{sub_val}, ...
%         handles.testopts, ...
%         wavfiles{list_val-1});
%     
% elseif list_val == 1 && length(wavfiles)==1
%     
%     % Run the first cell array in wavfiles
%     SIN_runTest(testID{test_val}, ...
%         subjectID{sub_val}, ...
%         handles.testopts, ...
%         wavfiles);
%     
% else 
%     
%     post_feedback(hObject, eventdata, handles, 'Error: List Selection', false);    
%     return;
%     
% end % if list_val ~= 1

% Post completion status
% post_feedback(hObject, eventdata, handles, [testID{test_val} ' complete'], true);    

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

% Get subjectID
subjectID = get(handles.subjectid, 'String'); 

% Get some basic information about directory structures and the like
opts = SIN_TestSetup('Defaults', subjectID);

% Try registering subject
[status, str]=SIN_register_subject(subjectID, 'register_tasks', {{'create'}}, opts); 

% Clear subject ID field
set(handles.subjectid, 'String', ''); 

% Post error message if we encounter one. 
post_feedback(hObject, eventdata, handles, str, status);
    
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

% Get available subjects
handles.subjectID = SIN_getsubjects; 

% Get available tests
handles.testlist = SIN_TestSetup('testlist'); 

% Populate subject popup
set(handles.subject_popup, 'String', [{'Select Subject'} handles.subjectID])

% Populate test list
set(handles.test_popup, 'String', [{'Select Test' handles.testlist{:}}]); 

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

% Default status
if ~exist('status', 'var') || isempty(status), status=-1; end % default to black text
% Set feedback color
switch status
    case {0}
        col='r';
    case {1}
        col='g';
    case {-1}
        col='k';
    otherwise
        error('Unknown color code'); 
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
