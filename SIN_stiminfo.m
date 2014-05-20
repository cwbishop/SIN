function [list_dir, wavfiles]=SIN_stiminfo(testID, opts, varargin)
%% DESCRIPTION:
%
%   Function to return stimulus lists (directories, filenames) for the
%   tests used in the SIN suite.
%
% INPUT:
%
%   testID: string, test ID as listed in SIN_defaults.testlist(:).name.
%
%   opts:   test options structure returned from SIN_TestSetup.m 
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

%% INITIALIZE RETURN VARIABLES
list_dir={};
wavfiles={}; 

switch testID
    
    case {'HINT (SNR-50)', 'PPT'}
        
        % Return directories based on defaults.hint.list_filt
        list_dir = regexpdir(opts.specific.root, opts.specific.list_regexp, false); 
        
        % Return file list for each directory
        %   - Create a shorthand name for directory (e.g., 'List01').
        %   - List all wav files within the directory.
        wavfiles={};
        list_name={};
        for i=1:length(list_dir)
            list_name{i}=list_dir{i}(regexp(list_dir{i}, opts.specific.list_regexp):end-1); 
            wavfiles{i}= regexpdir(list_dir{i}, '.wav$', false);
        end % for i=1:length(list_id)

    case {'ANL'}

        wavfiles=regexpdir(opts.specific.root, opts.specific.anl_regexp, false);
        
    otherwise 
        error(['No stimulus information available for ' testID]);        
end % switch testID
