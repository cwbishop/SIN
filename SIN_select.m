function selection = SIN_select(options, varargin)
%% DESCRIPTION:
%
%   This creates a simple GUI to aid the selection of various types of
%   options. Originally designed as a helper function for the dynamic
%   selection of playback and recording devices through PsychToolBox.
%
% INPUT:
%
%   options:    class containing data options. Supported classes include :
%                   - struct
%   
% Parameters:
%
%   'title':    string, title of figure.
%
%   'prompt':   string, user prompt (e.g., 'Select the playback device')
%
% OUTPUT:
%
%   selection:  the selection made
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

%% CONVER OPTIONS INTO A TEXT STRING
%   Text string will be placed in the description field of Selection_GUI.m.
description = class2txt(options);

%% OPEN GUI
%   Pass description to Selection_GUI
selection = Selection_GUI('description', {description}, 'title', d.title, 'prompt', d.prompt); 

%% NOW RETURN THE OPTION
selection = options(selection); 