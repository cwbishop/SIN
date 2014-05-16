function [list_dir, wavfiles]=SIN_stiminfo(testID, d, varargin)
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
% Parameters:
%
%   Fields to overwrite in d. Proved useful when retrieving wav files from
%   a specific directory from SIN_GUI. See SIN_defaults for a full field
%   description. Here are some commonly replaced values important to this
%   particular function
%
%       'list_filt':   regular expression, list filter.  
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
%       2) Cell array, wav file lists by directory
%
%   Examples:
%   
%       % Return HINT (SNR-50) information 
%       defs=SIN_defaults;
%       [list_dir, wavfiles]=SIN_stiminfo('HINT (SNR-50)', defs);
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

%% GET ADDITIONAL PARAMTERS
%   o is a structure with additional options set by user
o=varargin2struct(varargin{:}); 

% Overwrite values in d
flds=fieldnames(o);
for i=1:length(flds)
    d.(flds{i})=o.(flds{i});
end % for i=1:length(flds)

%% INITIALIZE RETURN VARIABLES
list_dir={};
wavfiles={}; 

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

    case {'ANL'}
        warning('ANL SIN_stiminfo not well vetted');                 
        opts=d.anl;
        wavfiles=regexpdir(opts.root, '.wav$', false);
    otherwise 
        error(['No stimulus information available for ' testID]);        
end % switch testID
