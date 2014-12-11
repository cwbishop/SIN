function create_wordspan_lookup(varargin)
%% DESCRIPTION:
%
%   Creates an XLSX lookup table to be used with SIN.
%
%   Note: the user should make sure wordspan_rename_files has been run
%   ahead of time. 
%
%   Note: Must have Word Span Score Sheets (three randomizations).xlsx in
%   the Word Span directory. 
%
% INPUT:
%
% Parameters:
%
%   'suffix':   string, suffix for file names. This is useful when
%               calibration or similar procedures require a name change. 
%
% OUTPUT:
%
%   A lookup table, dude!
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GET INPUT OPTIONS
d = varargin2struct(varargin{:});

%% INITIALIZE VARIABLES
track_number = [];
words = {};
alphabet = {}; 

% Get path information 
opts = SIN_TestSetup('Defaults', ''); 
wordspan_dir = fullfile(opts.general.root, 'playback', 'Word Span'); 

%% REPEAT FOR ALL SHEETS
%   There are 3 sheets in the XLSX file. 
for i=1:3
    
    % Read in the sheet
    [num, txt, raw] = xlsread(fullfile(wordspan_dir, 'Word Span Score Sheets (three randomizations).xls'), i);
    
    % We have to loop through the raw data, CWB thinks, in order to do this
    % in a timely fashion. Definitely better ways to get it done, but they
    % take too long to vet. 
    for n=1:size(raw,1)
        
        % Is this the beginning of a track?
        if isa(raw{n,2}, 'numeric') && isa(raw{n,3}, 'char') && ~any(isnan(raw{n,2}))
            
            track_number(end+1) = raw{n,2};
            words{end+1} = [];
            alphabet{end+1} = []; 
            is_track = true;
            
        elseif any(isnan(raw{n,2})) && any(isnan(raw{n,3}))
            
            is_track = false;
            
        end % start of a new track
        
        % Append the word to the word list for this track. 
        if is_track
            
            % Get target words
            if isempty(words{end})
                words{end} = raw{n,3};
            else
                words{end} = [words{end} ' ' raw{n,3}];
            end % if isempty(words{end})
            
            % Get alphabet information
            if isequal(lower(raw{n,5}), 'first')
                alph_key = '1';
            elseif isequal(lower(raw{n,5}), 'second')
                alph_key = '2';
            end % isequal ...
                
            % Append to growing alphabet information
            if isempty(alphabet{end})
                alphabet{end} = alph_key;
            else
                alphabet{end} = [alphabet{end} ';' alph_key];
            end % if isempty(alphabet ...
            
        end % end 
            
    end % 
end % for i=1:3

% Remove repeats
[track_number, ia] = unique(track_number); 
words = {words{ia}};
alphabet = {alphabet{ia}};

% Sort based on track number
[track_number, I] = sort(track_number); 
words = {words{I}};
alphabet = {alphabet{I}};

% Reshape them all so we can write a table more easily.
track_number = track_number';
words = words';
alphabet = alphabet'; 

% Append suffix to track names
track_name = [num2str(track_number) repmat(d.suffix, numel(track_number), 1)]; 

% Write data to table
writetable(table(track_name, words, alphabet), fullfile(wordspan_dir, ['WordSpan' d.suffix '.xlsx'])); 