function analysis_batch_export(subject_id, test_id, varargin)
%% DESCRIPTION:
%
%   This is a batch export function for SIN. The basic idea is to run a set
%   of fixed analyses for a set of subjects and test IDs. The digested data
%   points will be exported to an Excel spreadsheet (or equivalent) to
%   facilitate transcription to the data base. Or, alternatively, CWB might
%   write a wrapper function to automate the population operation.
%
% INPUT:
%
%   subject_id: cell array of subject IDs. If empty, the user will be
%               prompted with a selection GUI.
%
%   test_id:    cell array of test ID names. If empty, the user will be
%               promopted with a selection GUI.
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%
% Christopher W Bishop
%   University of Washington
%   04/2015

% Set defaults/prompt

% Loop through subjects
%   We'll create and write a table for each subject in a separate file for
%   now. CWB can't quite wrap his head around how to combine all fields
%   into a single document. 
for s = 1:length(subject_id)
    
    % Loop through tests
    for t = 1:length(test_id)
        
        % massive switch or if/elseif to select the correct analysis.
        if strfind(test_id{t}, 'HINT')
            
        end % if strfind
        
        % Add information to a growing table object
        
    end % for t=1:length(test_id)

    
end % for s=1:length(subject_id)
% Write table to CSV/XLSX.
