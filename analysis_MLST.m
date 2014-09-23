function results = analysis_MLST(results, varargin)
%% DESCRIPTION:
%
%   Function to analyze results from MLST. 
%
% INPUT:
%
%   results:    results structure from player_main
%
% OUTPUT:
%
%   results:    updated results structure with stored results information.
%
% Development:
%
%   1. Set flag for analyzing data by subcategory (e.g., high density, low
%   density, etc.).
%
% References:
%
%   1. Krick, Prusick, French, Gotch, Eisenberg, Young. "Assessing Spoken
%   Word Recognition in Children Who Are Deaf or Hard of Hearing: A
%   Translational Approach." J Am Acad Audiol 23:464-475 (2012)
%
% Christopher W Bishop
%   University of Washington
%   9/14

%% GET INPUT PARAMETERS
d=varargin2struct(varargin{:});

