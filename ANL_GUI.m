function varargout = ANL_GUI(varargin)
% ANL_GUI MATLAB code for ANL_GUI.fig
%      ANL_GUI, by itself, creates a new ANL_GUI or raises the existing
%      singleton*.
%
%      H = ANL_GUI returns the handle to a new ANL_GUI or the handle to
%      the existing singleton*.
%
%      ANL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANL_GUI.M with the given input arguments.
%
%      ANL_GUI('Property','Value',...) creates a new ANL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ANL_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ANL_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ANL_GUI

% Last Modified by GUIDE v2.5 25-May-2014 15:43:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ANL_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ANL_GUI_OutputFcn, ...
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


% --- Executes just before ANL_GUI is made visible.
function ANL_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ANL_GUI (see VARARGIN)
%
%   varargin{1} = options structure

% Choose default command line output for ANL_GUI
handles.output = hObject;

% Add Java Robot class to handles. This is used to execute "virtual key
% presses" to control 
%
% Here's where CWB got the idea
%   http://www.mathworks.com/matlabcentral/answers/5259-how-to-simulate-keyboard-key-inputs
% import java.awt.Robot; 
% import java.awt.event.*; 
% SimKey=Robot; 
% assignin('base', 'SimKey', SimKey); 

% handles.SimKey=SimKey;
% clear SimKey; 

% Assign test configuration
handles.opts=varargin{1}; 
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ANL_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ANL_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Return all handle information 
varargout{2} = handles; 

% --- Executes on button press in button_begin.
function button_begin_Callback(hObject, eventdata, handles)
% hObject    handle to button_begin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_R);
% handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_R);
VK_Press(handles, 5); 

% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in button_complete.
function button_complete_Callback(hObject, eventdata, handles)
% hObject    handle to button_complete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

VK_Press(handles, 4);
% eval(['handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(4) ')']);
% eval(['handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(4) ')']);

% --- Executes on button press in button_pause.
function button_pause_Callback(hObject, eventdata, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be definedprq in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Command line focus 
% http://stackoverflow.com/questions/10033078/matlab-implementing-what-ctrlc-does-but-in-the-code
% Simulate a "p" keypress (pauses player)
% cmdWindow = com.mathworks.mde.cmdwin.CmdWin.getInstance();
% cmdWindow.grabFocus();
% evalin('base', 'SimKey.keyPress(java.awt.event.KeyEvent.VK_P)');
% disp('this worked'); 
% evalin('caller', 'd.player.state=''pause'''); 
% eval(['handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(3) ')']);
% eval(['handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(3) ')']);
% handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_P);
VK_Press(handles, 3); 

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over button_pause.
function button_pause_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in button_increase.
function button_increase_Callback(hObject, eventdata, handles)
% hObject    handle to button_increase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_increase
% eval(['handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(1) ')']);
% eval(['handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(1) ')']);
VK_Press(handles, 1); 

% --- Executes on button press in button_decrease.
function button_decrease_Callback(hObject, eventdata, handles)
% hObject    handle to button_decrease (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_decrease
% eval(['handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(2) ')']);
% eval(['handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_' handles.opts.player.modcheck.keys(2) ')']);
VK_Press(handles, 2); 

function VK_Press(handles, key)
%% DESCRIPTION:
%
%   Function uses the java Robot class to press (and release) a key. This
%   allows us to use both the keyboard and the GUI simultaneously.
%
%   Here's where CWB got the idea ...
%
%       http://stackoverflow.com/questions/10033078/matlab-implementing-what-ctrlc-does-but-in-the-code
%
%   There were several other sites that suggested something similar. 
%
%   Here's a list of key codes
%
%       http://docs.oracle.com/javase/7/docs/api/java/awt/event/KeyEvent.html
%   
% INPUT:
%
%   key:    integer, corresponding to key number (returned from KbName)
%
% OUTPUT:
%
%   Key press
%
% Christopher W. Bishop
%   University of Washington
%   5/14

% eval(['handles.SimKey.keyPress(java.awt.event.KeyEvent.VK_' upper(KbName(handles.opts.player.modcheck.keys(key))) ')']);
% eval(['handles.SimKey.keyRelease(java.awt.event.KeyEvent.VK_' upper(KbName(handles.opts.player.modcheck.keys(key))) ')']);
