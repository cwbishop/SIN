function [iskey, words] = SIN_keywords(sentence, varargin)
%% DESCRIPTION:
%
%   In SIN, key words are capitalized and word options are enclosed in
%   square brackets and separated by a forward spash (e.g., [are/were] or
%   [ARE/WERE]). Words are separated by white space. 
%
%   This function accepts as its input a character string (e.g., a 
%   sentence) and returns a logical vector specifying if each word in the
%   sequence is a keyword or not.
%
% INPUT:
%
%   sentence:   string, sentence (e.g., 'a DOG ran in the PARK')
%
% OUTPUT:
%
%   iskey:  bool, logical vector of length N, where N is the number of
%           words in sentence. 
%
% Development:
%
%   1. Modularize punctuation removal routine.
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET WORDS FROM SENTENCE
%   Words are separated by white space.
words = strsplit(sentence); 

% Assume words are not keywords by default
iskey = false(numel(words),1); 

%% FIND KEYWORDS
% Determine keywords by capitalization in spreadsheet. 
for n=1:length(words)

    % Remove potential markups, and punctuation from words 
    tw = SIN_removepunctuation(words{n});
    
    % If all words are capitalized
    if all(isstrprop(tw, 'upper'))
        iskey(n)=true;
    else
        iskey(n)=false;
    end % if isstrprop ...

end % for i=1:length(w)