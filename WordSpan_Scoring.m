function varargout = WordSpan_Scoring(varargin)
% WORDSPAN_SCORING MATLAB code for WordSpan_Scoring.fig
%      WORDSPAN_SCORING, by itself, creates a new WORDSPAN_SCORING or raises the existing
%      singleton*.
%
%      H = WORDSPAN_SCORING returns the handle to a new WORDSPAN_SCORING or the handle to
%      the existing singleton*.
%
%      WORDSPAN_SCORING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WORDSPAN_SCORING.M with the given input arguments.
%
%      WORDSPAN_SCORING('Property','Value',...) creates a new WORDSPAN_SCORING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before WordSpan_Scoring_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to WordSpan_Scoring_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help WordSpan_Scoring

% Last Modified by GUIDE v2.5 09-Dec-2014 11:02:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @WordSpan_Scoring_OpeningFcn, ...
                   'gui_OutputFcn',  @WordSpan_Scoring_OutputFcn, ...
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


% --- Executes just before WordSpan_Scoring is made visible.
function WordSpan_Scoring_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to WordSpan_Scoring (see VARARGIN)

% Parameters:
%
%   'words':  cell array of words to score. (Max is 6)
%
% OUTPUT:
%
%   response_data:  a structure containing the following subfields
%
%       'recognition':  cell array, each element in the array contains the
%                       text-based recognition item. 
%
%       'alphabet': double array, contains the alphabet response. 1 = first
%                   half, 2 = second half.
%
%       'recall':   cell array, each element in the array contains the
%                   text-based recall. Items are stored in order listener
%                   recalls them. 
%
% Christopher W. Bishop
%   University of Washington
%   12/14

%% GET INPUT OPTIONS
opts = varargin2struct(varargin{:});

%% ADD CONSTANTS
%   Need to know the maximum number of words we will test. This is
%   currently 6 for Word Span
handles.max_set_size = 1;
% Set some safe defaults so the play button will work during development
if ~isfield(opts, 'words')
    
    % For i=1:handles.max_set_size
    for i=1:handles.max_set_size
        opts.words{i} = ''; 
    end % for i=1:handles.max_set_size
    
end % if ~isfield(opts, words) 

% Initialize return fields
handles.return_variables = struct( ...
    'recognition', {{}}, ...
    'judgment', [], ...
    'recall', {{}});

% Store in figure handle
%   This will store the options in the figure itself for easy retrieval in
%   callback functions below. 
handles.input = opts; 

% Clear options
%   This will prevent CWB from doing something stupid later.
clear opts; 

% Choose default command line output for WordSpan_Scoring
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Populate word fields 
word_box_root = 'text_word_'; 
words = cell(handles.max_set_size, 1); 
for i=1:handles.max_set_size
    
    % Overwrite default words if the user gives us anything to work with. 
    if ~isempty(handles.input.words{i})
        set(handles.([word_box_root num2str(i)]), 'String', handles.input.words{i});
    end % 
    
    % Get the words stored in the static text field
    %   Once the input words are applied, we'll use the static text field as
    %   "ground truth".     
    words{i} = get(handles.([word_box_root num2str(i)]), 'String');
    
end % for i=1:handles.opts.words

% Assign words to figure handles
handles.word_text = words; 

% Setup recall drop down lists.
update_recall_dropdown_list(hObject, eventdata, handles); 

% UIWAIT makes WordSpan_Scoring wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = WordSpan_Scoring_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Return control
% uiresume(handles.figure1); 

% --- Executes on selection change in popup_recall_1.
function popup_recall_1_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_1

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

function autoset_recall_text(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   Function designed to automatically populate a recall text box based on
%   user selection from a popup menu with a list of available words. 
%
% INPUT:
%
%   hObject, eventdata, handles ... standard stuff.
%
%   word_number:    word number
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Get corresponding recall word selection from recall popup menu
contents = cellstr(get(hObject,'String'));
the_word = contents{get(hObject,'Value')};

% Get the tag name for the text field
tag = get(hObject, 'Tag');
tag = strrep(tag, 'popup', 'text');

% Set the text field
set(handles.(tag), 'String', the_word); 

% --- Executes during object creation, after setting all properties.
function popup_recall_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_recall_1_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_1 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_1 as a double


% --- Executes during object creation, after setting all properties.
function text_recall_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1



function text_recognition_1_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_1 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_1 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles, 1);

function update_recognition_word_list(hObject, eventdata, handles, word_number)
%% DESCRIPTION ...

% Get the word from the corresponding text field
the_word = get(handles.(['text_recognition_' num2str(word_number)]), 'String'); 

% Add word to recognition return field
handles.return_variables.recognition{word_number} = the_word; 

% Update the recall list
update_recall_dropdown_list(hObject, eventdata, handles); 

function update_recall_dropdown_list(hObject, eventdata, handles)
%% DESCRIPTION ...

unique_recognition_words = unique(handles.return_variables.recognition);

% Need to update all drop down menus
for i=1:handles.max_set_size
    
    % Add the drop down list
    %   Recall that the drop down list is based on the unique entries of
    %   the word recognition list. These are pulled directly from the text
    %   fields in the Recognition and Judgment panel
    
    set(handles.(['popup_recall_' num2str(i)]), 'String', {'Word Selection', unique_recognition_words{:}}); 
        
end % for i=1:handles.max_set_size

% --- Executes during object creation, after setting all properties.
function text_recognition_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function panel_radio_recognition_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panel_radio_recognition_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in button_alphabet_first_1.
function button_alphabet_first_1_Callback(hObject, eventdata, handles)
% hObject    handle to button_alphabet_first_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_alphabet_first_1


% --- Executes on button press in button_alphabet_second_1.
function button_alphabet_second_1_Callback(hObject, eventdata, handles)
% hObject    handle to button_alphabet_second_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_alphabet_second_1


% --- Executes when selected object is changed in panel_radio_recognition_1.
function panel_radio_recognition_1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% This will automatically detect the radio buttons, get their values, and
% set the appropriate text field with the desired text. 

% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles, 1); 

function reset_recognition_radio_buttons(hObject, eventdata, handles, word_number)
%% DESCRIPTION: ...

% Set the values of all radio buttons to 
function autoset_recognition_text(hObject, eventdata, handles, word_number)
%% DESCRIPTION:
%
%   Function to automatically populate the recognition word text based on
%   radio button selection. This is designed to populate a the recognition
%   text following selection of Correct or NR radio buttons.
%
% INPUT:
%
%   hObject, eventdata, handles ... standard stuff
%
%   word_number:    the word number to update/populate.
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Get the radio button handles
children = get(handles.(['panel_radio_recognition_' num2str(word_number)]), 'Children');

% Determine which radio button(s) are pressed.
%   Theoretically, only one button can be selected at a time, but build in
%   check just in case CWB does something differently later.
is_nr = false;
is_correct = false;
update_string = '';
for i=1:numel(children)
    
    % Get button information
    h = get(children(i));     
    
    % Get response values from the radio button    
    if isequal(h.String, 'NR') && logical(h.Value)
        is_nr = true;
        update_string = 'NR';
    elseif isequal(h.String, 'Correct') && logical(h.Value)
        is_correct = true;   
        update_string = get(handles.(['text_word_' num2str(word_number)]), 'String');
    end % if isequal ...
    
    % Reset the radio button value to 0
    %   This allows the user to reselect the radio button again if he/she
    %   accidentally screws up the text entry. 
    set(children(i), 'Value', 0); 
    
end % i=1:nuem(children)

% Additional error checking
%   Make sure we don't have both radio buttons set (somehow).
%   Also confirm that we have at least one button selected. This seems
%   particularly superfluous, but better safe than sorry ;). 
if is_nr && is_correct
    error('Multiple radio buttons selected'); 
end % if is_nr & is_correct

if ~(is_nr || is_correct)
    error('Not radio button selected');
end % if ~(is_nr || is_correct) 

% Fill the text field. 
set(handles.(['text_recognition_' num2str(word_number)]), 'String', update_string);

% Update the recall dropdown word list
update_recognition_word_list(hObject, eventdata, handles, word_number);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function panel_radio_recognition_1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to panel_radio_recognition_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
