function createMLSTlookup
%% DESCRIPTION:
%
%   This function creates a suitable lookup table for MLST stimuli. This
%   uses the provided MLST word list (sent to CWB by Wu) to create
%   something closer to the HINT lookup table that is more robust. 
%
% INPUT:
%
%   IN: path to XLSX spreadsheet with MLST sentence, talker, and keyword
%       information in it
%
%   OUT:    path to XLSX spreadsheet that will serve as our lookup table
%
%
% Notes on file name formatting:
%
%   MLST filenames follow the format of :
%       SentencePositionWithinlist#_Talker#_Sentence#_LexicalCategory.FileExtension
%       (MP3/MP4)
%
%   As a regular expression, this looks like:
%
%       '[0-9]{1,2}_T[0-9]{1,2}_[0-9]{3}_[HL][DS].mp3$'
%
%   So a lot of the information we need to create the lookup table is
%   present in the filename itself.
%
%   
% Notes on Lookup Table format:
%
%   Here are the fields that are necessary in the resulting lookup table:
%
%   ID: a short-hand ID used to identify the list and sentence number
%   (e.g., 01_05 corresponds to list 01 and sentence 05).
%
%   REQUIRED FIELDS (to match HINT)
%
%   Filename:   contains the directory (e.g., List_01) and filename
%               information WITHOUT the file extension. This makes it
%               possible to use the same lookup table for MP3 and MP4
%               format types. 
%
%                   Ex.: 'List_01\1_T5_046_HS'
%
%   Legend: Sentence content. Keywords are marked using capital letters. 
%
%               Ex. 'if you KICK the TAP it will RUN'
%
%   Scoring units:  The number of keywords in the sentence
%   
%   ADDITIONAL (potentially useful) FIELDS
%
%   Talker: The talker ID (ranges from 1 - 10, see "Sheet2")
%
%   SentenceNum:  The sentence number (see second column of "Sheet1"
%
%   LexCat: Lexical category (see column 1 of "Sheet1")
%
% Development:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% GET AN APPROPRIATE OPTIONS SET
%   Use this to query lists and files below. We'll use most of the
%   informstion to generate most of the content we need. 
opts=SIN_TestSetup('MLST (Audio)', '');

%% GET FILENAMES
%   Use the filenames to generate most of the content
[list_dir, wavfiles] = SIN_stiminfo(opts);

%% LOAD SHEET 1
%   This contains the sentence text and target words. Also contains
%   sentence #, which will be used below to get talker information to
%   create filename information
[~,t,r]=xlsread(fullfile(opts.specific.root, 'MLST Sentence Lists.xlsx'), 1);

ID = {'ID'};
FilePath={'File Path'};
Sentence={'Legend'};
ScoringUnits = NaN;

for i=1:numel(wavfiles)
    
    for w=1:numel(wavfiles{i})
        
        % Breakdown to file parts
        [PATHSTR,NAME,EXT] = fileparts(wavfiles{i}{w});
        
        % Now break down file name into information we need
        C = strsplit(NAME, '_'); 
%         SentenceList#_Talker#_Sentence#_LexicalCategory.FileExtension
        SentList = str2num(C{1});
        Talker = C{2}; 
        SentNum = str2num(C{3}); 
        LexCat = C{4};
        
        % Find sentence information from XLS file
        % Note: the same sentence might be used more than once, so just
        % grab the first instance of the sentence since the keywords will
        % be the same in all sentences.
        ind = find([r{2:end,2}]==SentNum); 
        ind=ind(1) + 1 ; % add 1 back in to account for header being ommitted. 
        
        % Get key words
        keywords = {r{ind, 3:5}}; 
        
        % Get full sentence
        %   Make everything lower case. Below we'll capitalize the keywords
        %   for scoring purposes.
        sentence = lower(r{ind, 6});
        
        % Make SentenceLegend (SentLeg)
        for k=1:numel(keywords)
            
            % Find the key word
            ind = strfind(sentence, keywords{k});
            
            % Capitalize it (for keyword scoring)
            sentence(ind:ind + numel(keywords{k})-1) = upper(keywords{k}); 
            
        end % for k=1:numel(keywords)

        % Put all the information together into a format that's easy to
        % write to file 
        
        % Make sure we have at least two digits for list # and file number.
        ID{end+1,1} = sprintf('%02d_%02d', i, SentList);
        
        % Note that the file extension (.mp3 or .mp4) is omitted. This
        % makes data lookup easier down the road (CWB thinks, at least).
        FilePath{end+1, 1} = fullfile(PATHSTR(end-6:end), NAME); 
        Sentence{end+1, 1} = sentence; 
        ScoringUnits(end+1, 1) = numel(keywords); % this should always be 3 for MLST
%         FilePath(end+1, 1
        
    end % w=1:numel(wavfiles{i})
    
end % for i=1:numel(wavfiles)

display('');

% Create a table
t = table(ID, FilePath, Sentence, ScoringUnits);

% Write table to XLSX file
writetable(t, fullfile(opts.specific.root, 'MLST.xlsx')); 