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

% Last Modified by GUIDE v2.5 16-Apr-2015 09:53:24

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
handles.testlist = SIN_TestSetup('testlist', ''); 

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

    % Put options in workspace for user to play with
    assignin('base', 'opts', opts); 
    
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
handles.testlist = SIN_TestSetup('testlist', ''); 

% Should we apply the completed tests mask?
handles.test_filter = get(handles.checkbox_complete_tests,'Value');

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
    
    % If the value of the review popup is out of range, reset it to 1
    if get(handles.review_popup, 'Value') > length(tests)
        set(handles.review_popup, 'Value', 1)
    end

    % Populate popup
    set(handles.review_popup, 'String', {'Select Test' [char(tests)]});
    
end % if ~isequal ...

% If test_filter is set, then remove completed tests. That is, tests that
% we have saved data for. 
mask = true(length(handles.testlist), 1);
if handles.test_filter
    
    % Now see if each test is present in the list of subject tests.
    if ~isempty(handles.subject_tests)
        for i=1:length(handles.testlist)
            
            [~, is_complete] = test_checklist('subject_tests', {handles.subject_tests}, 'test_regexp', handles.testlist{i});         

            if any(is_complete)
                mask(i,1) = false;
            end % if any(is_complete)

        end % for i=1:length(handles.testlist)   
    end % if     
end % if handles.test_filter

% Stuff the handles 
handles.test_mask = mask; 


% If the popup value is out of range, reset to 1.
if get(handles.test_popup, 'Value') > length({handles.testlist{handles.test_mask}})
    set(handles.test_popup, 'Value', 1);
end

% Populate test list
set(handles.test_popup, 'String', [{'Select Test' handles.testlist{handles.test_mask}}]); 

% assign data to figure
guidata(handles.runSIN, handles);

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

% Post the changes to the figure. 
refresh(handles.runSIN); 

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

% Load the test
%   We want to call the callback button (as if the user had pressed "Load
%   Results") so the behavior is identical without CWB having to think. 
load_results_button_Callback(hObject, eventdata, handles)

% Replot results
% evalin('base', 'results(1).RunTime.analysis.fhand(results, results(1).RunTime.analysis.params);');
evalin('base', 'SIN_runAnalysis(results);'); 

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

% Load the test
%   We want to call the callback button (as if the user had pressed "Load
%   Results") so the behavior is identical without CWB having to think. 
load_results_button_Callback(hObject, eventdata, handles)

% Now review the recordings
evalin('base', ['SIN_review_recordings(results,' '''assign_to_workspace''' ', true, ' '''sound_playback''' ', 2, ' '''playback_channels''' ', 1:2 );']); 


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

%% LOAD DATA IN A SEMI-INTELLIGENT WAY
%   Check to see if the data currently living in the base workspace is what
%   we're trying to load. If so, then don't load it again. 

% Assume we don't need to load the results by default
load_results = false;

% If results doesn't exist in the base workspace, then we need to load it.
% Otherwise, we need to do more error checking
if ~evalin('base', ['exist(' '''results''' ',' '''var''' ')'])
    
    load_results = true;
    
else 
    
    % Look at the filename for the would-be loaded file
    [PATHSTR, new_filename, EXT] = fileparts(test2review);
    
    % Look at the filename for the already loaded file
    [PATHSTR, old_filename, EXT] = evalin('base', 'fileparts(results(1).RunTime.specific.saveData2mat);');
    
    % Compare the two filenames. If they're the same, then we don't need to
    % load anything. If they're different, we need to load.
    if ~isequal(new_filename, old_filename)
        load_results = true;
    end % if ~isequal ...
    
end % if ~evalin ...

% Only load the results again if they aren't already in the base work
% space. 
if load_results
    
    results = SIN_load_results({test2review});
    results = results{1}; 
    
    % Assign to workspace
    assignin('base', 'results', results); 
    
    % Load the corresponding test results
    post_feedback(hObject, eventdata, handles, ['Loading complete'], 1); % post error message to terminal
    
else
    post_feedback(hObject, eventdata, handles, ['Results already loaded.'], 1); % post error message to terminal
    
end % 


% --- Executes on button press in test_checklist_button.
function test_checklist_button_Callback(hObject, eventdata, handles)
% hObject    handle to test_checklist_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Here, we review the tests for a given subject.
contents = cellstr(get(handles.subject_popup,'String'));
[test_list, is_complete] = test_checklist('subject_id', contents{get(handles.subject_popup,'Value')});

% Display a warning for all tests that have not been run
if any(~is_complete)
    % If we have any incomplete tests, give a warning
    warndlg({sprintf('No Data Found for the Following Tests:\n'), test_list{~is_complete}}'); 
else
    message('All tests appear to be complete. But double/triple check!');
end % if / else


% --- Executes on button press in checkbox_complete_tests.
function checkbox_complete_tests_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_complete_tests (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_complete_tests

%% REFRESH POPUPS
refresh_popups(hObject, eventdata, handles); 
