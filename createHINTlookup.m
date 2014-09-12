function createHINTlookup(suffix)
%% DESCRIPTION:
%
%   Very basic function to create a lookup table for HINT. This basically
%   uses Wu's originaly HINT lookup table (well, a manually edited version
%   of it anyway ... CWB removed some of the file name information), and
%   appends a suffix to the file names. This allows modcheck_HINT_GUI to
%   successfully lookup sentence information.
%
% INPUT:
%
%   suffix:     suffix to attach to file names in new lookup table. 
%
% Christopher W. Bishop
%   University of Washington
%   8/14

% Load HINT options
opts = SIN_TestSetup('HINT (SNR-50, keywords, 1up1down)', '');

% Load original HINT lookup table 
%   Relevant information is in sheet 2
[~,t,r]=xlsread(fullfile(opts.specific.root, 'HINT (corrected).xlsx'), 2);

% Loop through all but the header and alter the file path column (2)
for i=2:size(r,1)
    
    % Get file parts
    if ~isnan(r{i,2})
        [PATHSTR,NAME,EXT] = fileparts(r{i,2});
    
        % new name
        %   Leave out extension. We are just matching root names. 
        fname = fullfile(PATHSTR, [NAME suffix]); 
    
        % Reassign to r
        r{i,2} = fname; 
    end 
    
end % for i=2:

% Write table
writetable(table(r), fullfile(opts.specific.root, ['HINT (' suffix ').xlsx'])); 