function results = analysis_WordSpan(results, varargin)
%% DESCRIPTION:
%
%   Analysis function for Word Span test. This is intended to be used in
%   conjunction with the results structure from SIN's player_main. 
%
%   Word span is scored in a few ways.
%
%   1) Recognition % correct. This is a score of the recognition portion of
%   the study. In other words, how accurately the listener was able to hear
%   (and recite) the target words immediately after presentation.
%
%   2) 
%   
% INPUT:
%
%   results:    results structure from SIN's player_main.
%
% Parameters:
%
%   ...
%
% OUTPUT:
%
%   results:    updated results structure
%
% Development:
%
%   1) Judgment scoring. According to instructions, the judgment scoring is
%   based on the actual word presented rather than the word in the
%   recognition phase (that is, the word the listener thought he or she
%   heard). This seems incorrect to CWB, but will score this way for
%   consistency. 
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GATHER PARAMETERS
d = varargin2struct(varargin{:});

% Get the response data
response_data = results.RunTime.player.modcheck.score_data; 

%% INITIALIZE COUNTERS
recognition_correct = zeros(6,1);
judgment_correct = zeros(6,1);
recall_correct = zeros(6,1); 
word_total = zeros(6,1);

%% SCORE EACH TRIAL (sentence)
%   Ignore the first 2 trials since they are practice
for i=3:numel(response_data)
    
    %   Get the "correct" labels (1 or 2) for alphabet, then
    %   compare with judgement.
    %
    %   Note: alphabet should be changed to the correct response based on
    %   the recognition field if development (1) is to be followed. 
    alphabet = str2num(cell2mat(strsplit(response_data(i).trial_table.alphabet{1}, ';')'));
    
    % Total number of words in this sentence serves as an index into the
    % array below. 
    word_number = sum(~cellfun(@isempty, response_data(i).words));
    for z=1:word_number
        
        % Words will be empty if there is not a word to score. 
        if ~isempty(response_data(i).words{z})
            
            % Increment word counter
            word_total(word_number) = word_total(word_number) + 1; 
            
            % Recognition score
            %   We don't need to exclude "NR" responses here because we are
            %   comparing to the words from the lookup table (no NR there).
            if isequal(response_data(i).words{z}, response_data(i).recognition{z})
                recognition_correct(word_number) = recognition_correct(word_number) + 1; 
            end 
            
            % Judgment score
            %   Judgment score should be based on the recognition response
            %   rather than the veridical word, CWB thinks. So let's do
            %   that instead. 
            %
            %   Refer to WordSpan_Scoring for details, but the gist is that
            %   there are 3 integers used to encode judgment responses.
            %       1: first half of alphabet
            %       2: second half of alphabet 
            %       3: NR (no response)
            %
            %   So it looks like we implicitly avoid potential scoring
            %   mistakes by uniquely coding the NR category.
            if isequal(response_data(i).judgment(z), alphabet(z))
                judgment_correct(word_number) = judgment_correct(word_number) + 1;
            end % if isequal ...
            
            % Recall score
            %   This is a potentially confusing thing to score since serial order
            %   is considered correct. 
            %
            %   Note: serial list information is ignored in scoring here. 
            %
            %   Note: Also note that we have to exlude "NR" responses here.
            %   We don't want to count a recognition "NR" as a correct
            %   recall if the recall is also "NR"
            if isequal(response_data(i).recognition{z}, response_data(i).recall{z}) ...
                    && ~isequal(response_data(i).recognition{z}, 'NR')
                recall_correct(word_number) = recall_correct(word_number) + 1; 
            end % if isequal
        
        end % if ~isempty(
        
    end % for z=1:...
end % for i=1:numel(response_data)

% Calculate average scores across all set sizes
%   This is equivalent to a weighted average across set sizes.
recognition_average = sum(recognition_correct)/sum(word_total);
judgment_average = sum(judgment_correct)/sum(word_total);
recall_average = sum(recall_correct)/sum(word_total); 
set_size = [2:numel(recognition_correct) + 1]';

% Convert to percentage
recognition_correct = recognition_correct./word_total;
judgment_correct = judgment_correct./word_total;
recall_correct = recall_correct./word_total;

%% SUMMARY PLOTS
if d.plot
    
    figure
    
    % Bar plot with all information 
    y = [[ (recognition_correct)'; (judgment_correct)'; (recall_correct)'] [recognition_average; judgment_average; recall_average]].*100;    
    bar(y');
    
    % Legend and labels
    legend('Recnognition', 'Judgment', 'Recall', 'location', 'eastoutside');     
    ylabel('Percentage Correct');
    xlabel('Set Size'); 
    
    % Set x-ticks and tick labels
    set(gca, 'XTick', set_size)
    
    % Get current labels
    l = get(gca, 'XTickLabel'); 
    
    for i=1:numel(l)
        l_new{i} = num2str(l(i));
    end
    l_new{end} = 'Average';
    set(gca, 'XTickLabel', l_new);    
    
end % if d.plot

%% CREATE A DATA TABLE TO DISPLAY FOR THE USER
% Get row names
for i=1:length(set_size(1:end))
    if i==1
        rname{i} = 'Null';
    else
        rname{i} = num2str(set_size(i));
    end % if i ==1
    
end % for 

% Create a table of results
%   These will be printed to terminal for easy scribbage. 
wordspan_results = table(set_size(1:end-1), recognition_correct(2:end)*100, judgment_correct(2:end).*100, recall_correct(2:end).*100, ...
    'VariableNames', {'set_size', 'recognition_correct', 'judgment_correct', 'recall_correct'});

display(wordspan_results);