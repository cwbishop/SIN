function cstr = SIN_removepunctuation(str, varargin)
%% DESCRIPTION:
%
%   Function to remove punctuaion from a string. Currently removes the
%   following characters
%
%       see clist in main function body for a list of removed punctuation. 
%
%       To remove other types of punctuation, add them to clist. The
%       function should then remove these items as well 
%
% INPUT:
%
%   str:    string to remove punctuation from
%
% OUTPUT:
%
%   cstr:   cleaned string
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% CREATE LIST OF PUNCTUATION TO REMOVE 
clist = ['[]-~?.' '''' '/,'];

% Initialize cstr
cstr = str; 

% Loop through all punctuation we want to remove, search for it, and
% replace with an empty string.
for i=1:numel(clist)
    
    % Find and replace
    cstr = strrep(cstr, clist(i), '');  
    
end % for i=1:numel(clist)