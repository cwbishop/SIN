function [d, o]=importHINT(varargin)
%% DESCRIPTION:
%
%   Function to import HINT information from XLSX file. Can also return
%   information specific satisfying search criteria (under development).
%
%   If not search criteria are provided, then information for the entire
%   list is returned. 
%
% INPUT:
%
%   'hintlist':     string, full path to file containing ID, file path, 
%                   legend, and scoring units. Default value set in
%                   SIN_defaults. 
%
% Search Criteria
%
%   'id':   sentence identifier
%   'file_path':    file path (relative to SIN directory)
%   '
%
% OUTPUT:
%
%   structure with the following fields:
%
%       'ID':   string, file identifier. Useful for logging.
%       'filepath':    Path to file
%       'sentence':    
%       'scoringunits':    number of scorable words
%
% Development:
%
%   1. This is ungodly slow. Like WOW slow. Even the basic criteria search
%   takes seconds. Need to speed this up somehow. 
%
%   2. Add support for delimited file import (e.g., CSV). This might be the
%   answer to (1) above as well. Just need to make the initialization way
%   (way) faster. 
%
%   3. This was written in one helluva hurry. Need to vet it. 
%
% Christopher W. Bishop
%   University of Washington 
%   5/14

%% GATHER ADDITIONAL PARAMETERS
d=varargin2struct(varargin{:}); 

% The player is made to work with a "SIN" style structure. If the user has
% defined inputs just at the commandline, then reassign to make it
% compatible.
if ~isfield(d, 'player')
    d.player = d; 
end % if

%% EMPTY o STRUCTURE
o=struct(); 

%% LOAD INFORMATION FROM XLSX FILE
%   Only load information from the text file if the data are not already
%   available in the data structure
if ~isfield(d.player.modcheck, 'id') || ~isfield(d.player.modcheck, 'filepath') || ~isfield(d.player.modcheck, 'sentence') || ~isfield(d.player.modcheck, 'scoringunits')
    
    [~,t,r]=xlsread(d.specific.hint_lookup.filename, d.specific.hint_lookup.sheetnum);
    
    % Clunky massaging necessary to read in scoring units properly 
    r=reshape({r{1:size(t,1),1:size(t,2)}}, size(t,1), size(t,2)); 

    % Get ID, file_path, sentence (legend), scoring_units
    id={r{2:end,1}}; % skip header
    filepath={r{2:end,2}}; % skip header
    sentence={r{2:end,3}}; % skip header
    scoringunits={r{2:end,4}}; % skip header, not working
    
    % Store the full information in the larger data structure passed around
    % portaudio_adaptiveplay and friends. 
    %
    % Below, we copy over the trial-specific information into a temporary
    % structure, o, that is then used for scoring purposes. 
    d.player.modcheck.id=id;
    d.player.modcheck.filepath=filepath;
    d.player.modcheck.sentence=sentence;
    d.player.modcheck.scoringunits=scoringunits;

else
    
    % If we've already loaded the table information, then copy over the
    % relevant fields. 
    id=d.player.modcheck.id;
    filepath=d.player.modcheck.filepath;
    sentence=d.player.modcheck.sentence;
    scoringunits=d.player.modcheck.scoringunits; 
    
end % if ~isfield ...

% Search by id
id_mask=false(length(id),1);
if isfield(d, 'id') && ~isempty(d.id)
    id_mask(ismember(id, d.id))=true; 
else
    id_mask=true(length(id), 1); 
end % if isfield(d ...

% Search by file_path
filepath_mask=false(length(id),1);
if isfield(d, 'filepath') && ~isempty(d.filepath)
    filepath_mask(ismember(filepath, d.filepath))=true; 
else
    filepath_mask=true(length(id), 1); 
end % if isfield(d ...

% Search by sentence
sentence_mask=false(length(id),1);
if isfield(d, 'sentence') && ~isempty(d.sentence)
    sentence_mask(ismember(sentence, d.sentence))=true; 
else
    sentence_mask=true(length(id), 1); 
end % if isfield(d ...

% Search by scoringunit
scoringunits_mask=false(length(id),1);
if isfield(d, 'scoringunits') && ~isempty(d.scoringunits)
    scoringunits_mask(ismember(scoringunits, d.scoringunits))=true; 
else
    scoringunits_mask=true(length(id), 1); 
end % if isfield(d ...

% Return information in structure form
mask=id_mask & filepath_mask & sentence_mask & scoringunits_mask;
o.id={id{mask}};
o.filepath={filepath{mask}};
o.sentence={sentence{mask}};
o.scoringunits={scoringunits{mask}};