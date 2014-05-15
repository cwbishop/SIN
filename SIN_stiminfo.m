function varargout=SIN_stiminfo(testID, d)
%% DESCRIPTION:
%
%   Function to return stimulus lists (directories, filenames) for the
%   tests used in the SIN suite.
%
% INPUT:
%
%   testID: string, test ID as listed in SIN_defaults.testlist(:).name.
%
%   d:  SIN structure. Typically loaded from SIN_defaults. Will not
%       automatically load. This to protect the user from doing something
%       stupid. 
%
% OUTPUT:
%
%   The output may vary by the test ID since different information might be
%   necessary to run each test. Varargout is used to accommodate these
%   potential needs.
%
%   HINT (SNR-50)
%
%       1) Cell array, full directory paths
%
%       2) cell array, short hand list names (e.g., 'List01', 'List02',...)
%
%       3) Cell array, wav file lists by directory
%
%
%   Examples:
%   
%       % Return HINT (SNR-50) information 
%       defs=SIN_defaults;
%       [list_dir, list_name, wavfiles]=SIN_stiminfo('HINT (SNR-50)', defs);
%
% Development:
%
%   1) Add support for other testing materials.
%
%   2) Create uniform return variables for ease of use, especially with
%   SIN_GUI.
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GET FILE INFORMATION
%   File information grabbed for test matching testID

switch testID
    
    case {'HINT (SNR-50)'}
        
        % Get HINT options
        opts=d.hint; 
        
        % Return directories based on defaults.hint.list_filt
        list_dir = regexpdir(opts.root, opts.list_filt, false);
        
        % Return file list for each directory
        %   - Create a shorthand name for directory (e.g., 'List01').
        %   - List all wav files within the directory.
        wavfiles={};
        list_name={};
        for i=1:length(list_dir)
            list_name{i}=list_dir{i}(regexp(list_dir{i}, opts.list_filt):end-1); 
            wavfiles{i}= regexpdir(list_dir{i}, '.wav$', false);
        end % for i=1:length(list_id)
        
        % Assign to return variable
        varargout{1}=list_dir;
        varargout{2}=list_name; 
        varargout{3}=wavfiles; 
        
    otherwise 
        error(['No stimulus information available for ' testID]);
        
end % switch testID
