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

% Last Modified by GUIDE v2.5 27-Oct-2014 10:13:24

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
% uiwait(handles.runSIN);


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

contents = cellstr(get(handles.test_popup,'String'));
testID = contents{get(handles.test_popup,'Value')};
% Error check for test selection
%   User must select a valid test before we can run it.
if isequal(testID, 'Select Test')
    post_feedback(hObject, eventdata, handles, ['Invalid Test ID: ' testID ], 0); % post error message to terminal    
    return
end % 

% Error check for subject ID
%   User must select a valid subject ID. If the ID isn't valid, then toss
%   an error. 
if isequal(subjectID, 'Select Subject')
    post_feedback(hObject, eventdata, handles, ['Invalid Subject ID: ' subjectID ], 0); % post error message to terminal
else
    % Get test options from SIN_TestSetup
    opts = SIN_TestSetup(testID, subjectID); 

    post_feedback(hObject, eventdata, handles, ['Running: ' testID ], -1); % post error message to terminal
    % Run the test
    %   - Playlist automatically handled by SIN_getPlaylist (Called from
    %   SIN_runTest). 
    SIN_runTest(opts); 

    post_feedback(hObject, eventdata, handles, [testID ' complete!'], true);    
end % if isequal(subjectID ...

% Repopulate fields after test is complete.
%   This will ensure that the subject's completed test list is up to date.
refresh_popups(hObject, eventdata, handles);

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

% Need to populate Subject Tests field
% [tests, dtimes] = SIN_gettests('subjectID', contents{get(hObject,'Value')}); 
% set(handles.subjecttests, tests);
% set(handles.subjecttesttimes, dtimes); 

% Refresh popups
refresh_popups(hObject, eventdata, handles);

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

% Attach updated information to figure
guidata(hObject, handles);

% Get tests for subject
% handles.subjecttests = SIN_gettests(
% Populate subject popup
set(handles.subject_popup, 'String', [{'Select Subject'} handles.subjectID])

% Get selected subjectID
contents = cellstr(get(handles.subject_popup,'String'));
subjectID = contents{get(handles.subject_popup,'Value')};

% Use subjectID to populate subject tests field
if ~isequal(subjectID, 'Select Subject'); 
    [tests, dtimes] = SIN_gettests('subjectID', subjectID); 
    
    % Assign values to handles
    handles.subject_tests = tests;
    handles.test_times = dtimes; 
    
    % Populate popup
    set(handles.review_popup, 'String', {'Select Test' [char(tests)]});
    
end % if ~isequal ...

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


% --- Executes on button press in button_clearerrors.
function button_clearerrors_Callback(hObject, eventdata, handles)
% hObject    handle to button_clearerrors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SIN_ClearErrors; 


% --- Executes on selection change in review_popup.
function review_popup_Callback(hObject, eventdata, handles)
% hObject    handle to review_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns review_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from review_popup

% Set review test
contents = cellstr(get(handles.review_popup,'String'));
test2review = contents{get(handles.review_popup,'Value')};

% Assign to handles
handles.test2review = test2review;

% Attach to GUI
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function review_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to review_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Get list of completed tests for given subject


% --- Executes on button press in review_results_button.
function review_results_button_Callback(hObject, eventdata, handles)
% hObject    handle to review_results_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get test2review
%   test2review only populated if a test has been selected from the drop
%   down menu. If one is not selected, then just return control. 
try
    test2review = handles.test2review;
catch
    return
end 

% Post to terminal
post_feedback(hObject, eventdata, handles, ['Loading: ' test2review  ], -1); % post error message to terminal

% Load the test
results = load(test2review);
results = results.results;

% Load the corresponding test results
post_feedback(hObject, eventdata, handles, ['Loading complete'], 1); % post error message to terminal

% Replot results
results(1).RunTime.analysis.fhand(results, results(1).RunTime.analysis.params);


% --- Executes on button press in review_recordings_button.
function review_recordings_button_Callback(hObject, eventdata, handles)
% hObject    handle to review_recordings_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load test to review
%   Field will only be populated if a test is selected in the review panel.
%   If not, then just return without doing anything
try
    test2review = handles.test2review;
catch
    return
end 

% Post to terminal
post_feedback(hObject, eventdata, handles, ['Loading: ' test2review  ], -1); % post error message to terminal

% Load the test
results = load(test2review);
results = results.results;

% Load the corresponding test results
post_feedback(hObject, eventdata, handles, ['Loading complete'], 1); % post error message to terminal

% Now review the recordings
SIN_review_recordings(results, 'assign_to_workspace', true); 


% --- Executes on button press in button_stop.
function button_stop_Callback(hObject, eventdata, handles)
% hObject    handle to button_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SIN_ClearErrors; 


% --- Executes on button press in load_results_button.
function load_results_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_results_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load test results
%   Field will only be populated if a test is selected in the review panel.
%   If not, then just return without doing anything
try
    test2review = handles.test2review;
catch
    return
end 

% Post to terminal
post_feedback(hObject, eventdata, handles, ['Loading: ' test2review  ], -1); % post error message to terminal

% Load the test
results = load(test2review);
results = results.results;

% Assign to workspace
assignin('base', 'results', results); 

% Load the corresponding test results
post_feedback(hObject, eventdata, handles, ['Loading complete'], 1); % post error message to terminal
