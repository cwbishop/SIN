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

% Last Modified by GUIDE v2.5 18-Dec-2014 14:38:28

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
%       'words':    cell array, scored words. 
%
%       'recognition':  cell array, each element in the array contains the
%                       text-based recognition item. 
%
%       'judgement': double array, contains the alphabet response. 1 = first
%                   half, 2 = second half.
%
%       'recall':   cell array, each element in the array contains the
%                   text-based recall. Items are stored in order listener
%                   recalls them. 
%
%       'is_scored':    bool, true indicates that the word should be scored
%                       offline. False indicates the "word" was not scored
%                       for some reason (e.g., if fewer than 6 words were
%                       supplied to the GUI for scoring). 
%
% Christopher W. Bishop
%   University of Washington
%   12/14

%% GET INPUT OPTIONS
opts = varargin2struct(varargin{:});

%% ADD CONSTANTS
%   Need to know the maximum number of words we will test. This is
%   currently 6 for Word Span
handles.max_set_size = 6;

% Set some safe defaults so the play button will work during development.
% This may lead to some issues later on regarding which boxes are visible
% or not, but CWB will have to deal with that later. 
if ~isfield(opts, 'words')
    
    % For i=1:handles.set_size
    for i=1:handles.max_set_size
        opts.words{i} = ''; 
    end % for i=1:handles.set_size    

end % if ~isfield(opts, words) 

% Also need to know the set size of 
handles.set_size = numel(opts.words); 

% % Initialize return fields
% handles.return_variables = struct( ...
%     'recognition', {{}}, ...
%     'judgment', [], ...
%     'recall', {{}});

% Store in figure handle
%   This will store the options in the figure itself for easy retrieval in
%   callback functions below. 
handles.input = opts; 

% Clear options
%   This will prevent CWB from doing something stupid later.
clear opts; 

% Choose default command line output for WordSpan_Scoring
handles.output = hObject;

% Populate word fields 
word_box_root = 'text_word_'; 
words = cell(handles.max_set_size, 1); 
for i=1:handles.set_size
    
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

% Initialize GUI and return variables
%   We'll want to set visibility of field entries based on the number of
%   words provided by the user. 
%
%   Also want to initialize return variable fields in a sensible format
%   with appropriate "null" codes. 
initialize_wordspan_gui(hObject, eventdata, handles); 

% UIWAIT makes WordSpan_Scoring wait for user response (see UIRESUME)
uiwait(handles.figure1);

function handles = initialize_wordspan_gui(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   Function initializes the word span gui and return variables.
%
% INPUT:
%
%   handles:    GUI handles structure.
%
% OUTPUT:   
%
%   handles:    updated handles structure
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Initialize return variables
handles.return_variables.words = cell(handles.max_set_size,1); 
handles.return_variables.recognition = cell(handles.max_set_size,1); 
handles.return_variables.recall = cell(handles.max_set_size, 1); 
handles.return_variables.judgment = nan(handles.max_set_size,1); 
handles.return_variables.is_scored = false(handles.max_set_size,1); 

% Set visibility of scoring boxes 
for i=1:handles.max_set_size
    
    % Initialize the to-be-scored word
    handles.return_variables.words{i,1} = handles.word_text{i};
    
    % Initialize recognition with empty strings
    %   Need to initialize with an empty string otherwise update_recall
    %   throws a shoe    
    handles.return_variables.recognition{i} = ''; 
    handles.return_variables.recall{i} = ''; 
    
    % Need to reset all scoring panel information. This includes:
    %   - Correct/NR Radio buttons (this is done automatically elsewhere)
    %   - recognition text field (reset below)
    %   - judgment radio button (reset below)
    %   - Recall list (update_recall_dropdown_list)
    %   - Recall text entries (reset here) 
    %   - Recall drop down box needs to be reset as well.
    set(handles.(['text_recognition_' num2str(i)]), 'String', ''); 
    set(handles.(['button_alphabet_first_' num2str(i)]), 'Value', 0);
    set(handles.(['button_alphabet_second_' num2str(i)]), 'Value', 0);
    set(handles.(['button_alphabet_nr_' num2str(i)]), 'Value', 0);
    set(handles.(['text_recall_' num2str(i)]), 'String', '');     
    set(handles.(['popup_recall_' num2str(i)]), 'Value', 1); 
    
    % We want to set all scoring boxes <= handles.set_size as visible, but
    % those greater than handles.set_size as invisible.
    if i <= handles.set_size
        is_visible = 'On';
        handles.return_variables.is_scored(i) = true; 
    else
        is_visible = 'Off';
    end % if i <= handles.set_size
   
    % Set visibility of scoring stuff.
    set(handles.(['panel_word_' num2str(i)]), 'Visible', is_visible);
    set(handles.(['panel_recall_' num2str(i)]), 'Visible', is_visible);
    
end % for i=1:handles.max_set_size 

% Reset recognition word list and recall popup menus
update_recognition_word_list(hObject, eventdata, handles);  

% Set judgment information
update_judgment(hObject, eventdata, handles); 

% Get the updated GUI data 
%   These data are updated by update_*
handles = guidata(handles.figure1); 

% Put the data back in the figure 
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = WordSpan_Scoring_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
varargout{1} = handles.return_variables; 

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

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

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

% Update the recall list
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

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

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
update_recognition_word_list(hObject, eventdata, handles);

function update_recall_word_list(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   Updates the recall responses in the return_variables structure. Like
%   update_recognition_word_list, this function will update all recall
%   entries each time it is called. This has the advantages discussed in
%   update_recognition_word_list. 
%
% INPUT:
%
%   XXX
%
% OUTPUT:
%
%   updated handles structure in guidata.
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Loop through all recall entries
for i=1:handles.set_size
    
    % Get the recall word
    the_word = upper(get(handles.(['text_recall_' num2str(i)]), 'String'));
    
    % Set the word again to make sure the word in the text box is
    % capitalized.
    set(handles.(['text_recall_' num2str(i)]), 'String', the_word);
    
    % Update handles structure
    %   Force words to be all uppercase. Will make scoring easier later.
    handles.return_variables.recall{i} = the_word; 
    
end % for i=1:handles.set_size

% Update GUIDATA
guidata(handles.figure1, handles);

function update_recognition_word_list(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   Function updates the recognition responses in the return_variables
%   structure. It will update all entries each time it is called. This
%   allows the user to call the function as a callback after each entry is
%   completed *or* for validation purposes after the user presses the
%   "Continue" function.
%
% INPUT:
%
%   XXX
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Loop through all fields
for i=1:handles.set_size
    
    % Get the word from the corresponding text field
    the_word = upper(get(handles.(['text_recognition_' num2str(i)]), 'String')); 

    % Set the word again.
    %   This is necessary to ensure that the text in the field is
    %   capitalized. 
    set(handles.(['text_recognition_' num2str(i)]), 'String', the_word);
    
    % Add word to recognition return field
    %   Force words to be upper case
    handles.return_variables.recognition{i} = the_word;     

end % for i=1:handles.set_size

% Update the recall list
%   Only need to call this after all fields have repopulated rather than
%   for every word as originally written. 
update_recall_dropdown_list(hObject, eventdata, handles); 

% Update handles structure
guidata(handles.figure1, handles);

function update_recall_dropdown_list(hObject, eventdata, handles)
%% DESCRIPTION ...

% We need to ensure that "NR" is an option. To tack it onto the recognition
% list and let the code sort out the mess.
unique_recognition_words = unique({handles.return_variables.recognition{:}, 'NR'}');

% Note: we want to remove empty fields from this list *and* sort the list
% to ease searching.
mask = true(size(unique_recognition_words));
for i=1:numel(unique_recognition_words)
    
    if isempty(unique_recognition_words{i})
        mask(i) = false;
    end % isempty ...    
end % for i=1:unique_recognition_words

% Apply the mask
unique_recognition_words = {unique_recognition_words{mask}}; 

% Make sure we have *something* in unique_recognition_words
%   If we only have empty strings in unique_recognition_words, then the
%   variable will be an empty cell array by this point. This will result in
%   the popup menus disappearing when they are updated. This catch makes
%   sure there's *something* to put in the popup menus so they don't
%   disappear.
if numel(unique_recognition_words) == 0
    unique_recognition_words{1} = '';
end % if numel ..

% Sort the list
unique_recognition_words = sort(unique_recognition_words); 

% Need to update all drop down menus
for i=1:handles.set_size
    
    % Add the drop down list
    %   Recall that the drop down list is based on the unique entries of
    %   the word recognition list. These are pulled directly from the text
    %   fields in the Recognition and Judgment panel    
    
    set(handles.(['popup_recall_' num2str(i)]), 'String', {unique_recognition_words{:}}); 
        
end % for i=1:handles.set_size

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
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);

function autoset_recognition_text(hObject, eventdata, handles)
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
% Christopher W Bishop
%   University of Washington
%   12/14

% Is this a No Response or Correct button?
button_label = get(hObject, 'String'); 

% Get the tag name for the corresponding text field
tag = get(hObject, 'Tag'); 
tag = strrep(tag, '_correct', '');
tag = strrep(tag, '_noresponse', ''); 
tag = strrep(tag, 'button', 'text'); 

if isequal(button_label, 'Correct')
    update_text = get(handles.(strrep(tag, 'recognition', 'word')), 'String'); 
elseif isequal(button_label, 'NR')
    update_text = 'NR'; 
else
    error('Unrecognized button label'); 
end % if isequal(button_label, ...

% Update the recognition text field
set(handles.(tag), 'String', update_text); 

% Reset the radio button to 0
set(hObject, 'Value', 0); 

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% We need to validate user selections as well.
status = validate_responses(hObject, eventdata, handles, 'summary_message', true); 

% Return control, but only if all input fields are valid. 
if status
    uiresume(handles.figure1); 
end % if status

function status = validate_responses(hObject, eventdata, handles, varargin)
%% DESCRIPTION:
%
%   Function to verify that all required responses are filled out with
%   appropriate values. This includes the following checks:
%
%       1) A valid text value has been entered for recognition responses.
%       
%       2) A judgment for all active entries has been selected. 
%
%       3) A sanity check in the event that no recall entries have been
%       entered. This will prevent cases when users accidentally hit
%       continue before entering recall information.
%
% INPUT:
%
%   hObject, eventdata, handles ... standard stuff
%
% Parameters:
%
%   'summary_message':  bool, if set then a summary message is displayed if
%                       any fields are left empty. 
%
% OUTPUT:
%
%   status: bool, true if all data entries are complete and valid. False
%           otherwise.
%
% Christopher W Bishop
%   University of Washington
%   12/14

% Gather input parameters
opts = varargin2struct(varargin{:});

% Initialize validation check variables
recognition_status = false(handles.set_size,1);
judgment_status = false(handles.set_size,1); 
recall_status = false(handles.set_size,1);

%% VALIDATION LOOP
%   The validation loop will check each (active) word and return TRUE if
%   all is well and FALSE otherwise. This will allow us to create a summary
%   message at the end describing the (potentially) missing information. 
for i=1:handles.set_size
    
    % Recognition check
    %   We'll say this is OK provided the entry is not empty. Entries
    %   should have a string of some kind. NR is used in the event that
    %   study participants do not respond. 
    if isempty(handles.return_variables.recognition{i})
        recognition_status(i) = false; 
    else
        recognition_status(i) = true; 
    end % if isempty
    
    % Judgment check
    %   Judgment should be either 1 or 2. 0s indicate the field is blank
    %   and nan indicates the field is unscored. 
    %
    %   Judgment can also be 3 now for "no response" (NR). 
    if ~ismember(handles.return_variables.judgment(i), [1 2 3])
        judgment_status(i) = false;
    else
        judgment_status(i) = true;
    end % if handles.return_variables ... 
    
    % Recall check
    %   Recall fields may indeed be empty. Or should we require the user to
    %   enter NR in the remaining empty fields? That might make string
    %   matching later a bit of a nightmare, but would at least we'd know
    %   the experimenter didn't omit something by mistake. I think the
    %   latter is the way to go.
    if isempty(handles.return_variables.recall{i})
        recall_status(i) = false;
    else
        recall_status(i) = true;
    end % if isempty(handles.return_variables.recall{i}
       
end % for i=1:handles.set_size

% Now what do we do with the information?
%   Let's create a summary message here.
recognition_message = ['Missing recognition entries: [' num2str(find(~recognition_status))' ']'];
judgment_message = ['Missing judgment entries: [' num2str(find(~judgment_status))' ']'];
recall_message = ['Missing recall entries: [' num2str(find(~recall_status))' ']'];

status = true; 
summary_message = [];
if any(~recognition_status)
    summary_message = strvcat(summary_message, recognition_message);
    status = false;
end 

if any(~judgment_status)
    summary_message = strvcat(summary_message, judgment_message);
    status = false;
end 

% This check requires an entry for every recall slot. Probably the safest
% (for now) until someone threatens to smack CWB for forcing them to input
% blanks for all answers. 
if any(~recall_status)
    summary_message = strvcat(summary_message, recall_message);
    status = false;
end 

% Display the message as an error message, but only if user sets the
% summary_message flag
if ~status && opts.summary_message
    errordlg(summary_message);
end 

% --- Executes during object deletion, before destroying properties.
function panel_radio_recognition_1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to panel_radio_recognition_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function text_recognition_2_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_2 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_2 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text_recognition_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recognition_3_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_3 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_3 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text_recognition_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recognition_4_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_4 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_4 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text_recognition_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recognition_5_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_5 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_5 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text_recognition_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recognition_6_Callback(hObject, eventdata, handles)
% hObject    handle to text_recognition_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recognition_6 as text
%        str2double(get(hObject,'String')) returns contents of text_recognition_6 as a double

% Adds the word to the recognition word list
update_recognition_word_list(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text_recognition_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recognition_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in panel_radio_recognition_2.
function panel_radio_recognition_2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);


% --- Executes when selected object is changed in panel_radio_recognition_3.
function panel_radio_recognition_3_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_3 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);


% --- Executes when selected object is changed in panel_radio_recognition_4.
function panel_radio_recognition_4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_4 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);


% --- Executes when selected object is changed in panel_radio_recognition_5.
function panel_radio_recognition_5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);


% --- Executes when selected object is changed in panel_radio_recognition_6.
function panel_radio_recognition_6_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_radio_recognition_6 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function that handles this stuff.
autoset_recognition_text(hObject, eventdata, handles); 

% Repopulate the recall drop down box
update_recognition_word_list(hObject, eventdata, handles);


% --- Executes on selection change in popup_recall_6.
function popup_recall_6_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_6

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function popup_recall_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_recall_6_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_6 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_6 as a double

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function text_recall_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_recall_5.
function popup_recall_5_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_5

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function popup_recall_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recall_5_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_5 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_5 as a double

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 


% --- Executes during object creation, after setting all properties.
function text_recall_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_recall_4.
function popup_recall_4_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_4

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function popup_recall_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recall_4_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_4 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_4 as a double

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function text_recall_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recall_2_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_2 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_2 as a double

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function text_recall_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_recall_2.
function popup_recall_2_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_2

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function popup_recall_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_recall_3.
function popup_recall_3_Callback(hObject, eventdata, handles)
% hObject    handle to popup_recall_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_recall_3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_recall_3

% Call a centralized function designed to automatically populate the recall
% text field
autoset_recall_text(hObject, eventdata, handles); 

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function popup_recall_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_recall_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_recall_3_Callback(hObject, eventdata, handles)
% hObject    handle to text_recall_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_recall_3 as text
%        str2double(get(hObject,'String')) returns contents of text_recall_3 as a double

% Update recall word list in return_variables structure
update_recall_word_list(hObject, eventdata, handles); 

% --- Executes during object creation, after setting all properties.
function text_recall_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_recall_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in panel_judgment_1.
function panel_judgment_1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 

function update_judgment(hObject, eventdata, handles)
%% DESCRIPTION:
%
%   This function updates the judgment field of the return_variables
%   structure.
%
% INPUT:
%
%   XXX
%
% Christopher W Bishop
%   12/14

% Probably worth looping through all judgment fields and updating them all.
% This will make it easier to run this either after a radio button is
% pressed or, alternatively, as a final query after the "Continue" button
% is pressed. 

for i=1:handles.set_size
    
    % Figure out which button has been pressed based the presence of
    % "first" or "second" in the tag name. This is potentially disastrous,
    % but CWB can't think of a better way to do it at present. I hate
    % string matching ...
    is_first = get(handles.(['button_alphabet_first_' num2str(i)]), 'Value');
    is_second = get(handles.(['button_alphabet_second_' num2str(i)]), 'Value');
    is_nr = get(handles.(['button_alphabet_nr_' num2str(i)]), 'Value');
    
    response = logical([is_first is_second is_nr]);
    
    % Basic error checks to make sure multiple selections have not been
    % made.
    if numel(find(response)) > 1 
        error(['Multiple judgments for word ' num2str(i)]);
    elseif is_first
        judgment = 1;
    elseif is_second
        judgment = 2; 
    elseif is_nr
        judgment = 3; 
    else
        % Encode empty judgments as a 0.
        judgment = 0; 
    end % if logical ...
    
    handles.return_variables.judgment(i) = judgment; 
    
end % i=1:handles.set_size

% Update GUI handles 
guidata(handles.figure1, handles);


% --- Executes when selected object is changed in panel_judgment_2.
function panel_judgment_2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 


% --- Executes when selected object is changed in panel_judgment_3.
function panel_judgment_3_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_3 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 


% --- Executes when selected object is changed in panel_judgment_4.
function panel_judgment_4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_4 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 


% --- Executes when selected object is changed in panel_judgment_5.
function panel_judgment_5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 


% --- Executes when selected object is changed in panel_judgment_6.
function panel_judgment_6_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_judgment_6 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Call a centralized function to add the specified judgment value to the
% return_variables field of data handles.
update_judgment(hObject, eventdata, handles); 


% --- Executes on button press in button_alphabet_nr_1.
function button_alphabet_nr_1_Callback(hObject, eventdata, handles)
% hObject    handle to button_alphabet_nr_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_alphabet_nr_1
