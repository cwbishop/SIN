function varargout = Instructions(varargin)
% INSTRUCTIONS MATLAB code for Instructions.fig
%      INSTRUCTIONS, by itself, creates a new INSTRUCTIONS or raises the existing
%      singleton*.
%
%      H = INSTRUCTIONS returns the handle to a new INSTRUCTIONS or the handle to
%      the existing singleton*.
%
%      INSTRUCTIONS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INSTRUCTIONS.M with the given input arguments.
%
%      INSTRUCTIONS('Property','Value',...) creates a new INSTRUCTIONS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Instructions_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Instructions_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Instructions

% Last Modified by GUIDE v2.5 02-Oct-2014 15:07:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Instructions_OpeningFcn, ...
                   'gui_OutputFcn',  @Instructions_OutputFcn, ...
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


% --- Executes just before Instructions is made visible.
function Instructions_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Instructions (see VARARGIN)

%% GET PARAMETERS
d = varargin2struct(varargin{:});

% Choose default command line output for Instructions
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Set body and heady fields
set(handles.header_text, 'String', d.header);
set(handles.body_text, 'String', d.body); 

% UIWAIT makes Instructions wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = Instructions_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Close the figure
% close(handles.figure1);

% --- Executes on button press in button_continue.
function button_continue_Callback(hObject, eventdata, handles)
% hObject    handle to button_continue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Resume normal control flow
uiresume(handles.figure1);

 
