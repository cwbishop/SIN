function [list_dir, wavfiles]=SIN_stiminfo(opts, varargin)
%% DESCRIPTION:
%
%   Function to return stimulus lists (directories, filenames) for the
%   tests used in the SIN suite.
%
% INPUT:
%
%   opts:   test options structure returned from SIN_TestSetup.m.
%
%           Alternatively, opts can be a simple string of the testID.
%           Either should get you to the same place, CWB thinks.
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

% If user passed in the options structure, then grab the testID from a
% likely location.
%
% If the user provides a string, assume it's the testID and assign
% accordingly. 
if isstruct(opts)
    testID = opts.specific.testID; 
elseif isa(opts, 'char')
    testID=opts;
end % if isstruct(opts)

% Return directories based on defaults.hint.list_filt
list_dir = regexpdir(opts.specific.root, opts.specific.list_regexp, false); 

% If we didn't find any list information, then assume stimuli are in the
% root directory
if isempty(list_dir)
    list_dir{1} = opts.specific.root;
end % 

% Return file list for each directory
%   - Create a shorthand name for directory (e.g., 'List01').
%   - List all wav files within the directory.
wavfiles={};
list_name={};
% if ~isempty(list_dir)
for i=1:length(list_dir)            
    list_name{i}=list_dir{i}(regexp(list_dir{i}, opts.specific.list_regexp):end-1); 
    wavfiles{i}= regexpdir(list_dir{i}, opts.specific.wav_regexp, false);
end % for i=1:length(list_id)
% else 
%     wavfiles{1}= regexpdir(, opts.specific.wav_regexp, false);
% end % 

% switch testID
%     
%     case {'HINT (SNR-50, keywords, 1up1down)', 'PPT', 'HINT (SNR-50, NALadaptive)', 'MLST (Audio, Aided, SSN, 65 dB SPL, +8 dB SNR)', 'MLST (AV, Unaided, SSN, 65 dB SPL, +8 dB SNR)', 'MLST (AV, Aided, SSN, 65 dB SPL, +8 dB SNR)', 'MLST (Audio, Unaided, SSN, 65 dB SPL, +8 dB SNR)', 'MLST (Audio, Aided, SSN, 65 dB SPL, +8 dB SNR)'}
%         
%         % Return directories based on defaults.hint.list_filt
%         list_dir = regexpdir(opts.specific.root, opts.specific.list_regexp, false); 
%         
%         % Return file list for each directory
%         %   - Create a shorthand name for directory (e.g., 'List01').
%         %   - List all wav files within the directory.
%         wavfiles={};
%         list_name={};
%         for i=1:length(list_dir)            
%             list_name{i}=list_dir{i}(regexp(list_dir{i}, opts.specific.list_regexp):end-1); 
%             wavfiles{i}= regexpdir(list_dir{i}, opts.specific.wav_regexp, false);
%         end % for i=1:length(list_id)
% 
%     case {'ANL', 'ANL (MCL-Too Loud)', 'ANL (MCL-Too Quiet)', 'ANL (MCL-Estimate)', 'ANL (BNL-Too Loud)', 'ANL (BNL-Too Quiet)','ANL (BNL-Estimate)', 'Hagerman' }
% 
%         wavfiles=regexpdir(opts.specific.root, opts.specific.wav_regexp, false);
%     
%     case {'noise'}
%         
%         % Return noise samples stored in noise directory
%         wavfiles=regexpdir(opts.general.noiseDir, opts.general.noise_regexp, false); 
%         
%     case {'Calibrate'}
%         
%         wavfiles=regexpdir(opts.specific.calstimDir, opts.specific.calstim_regexp, false); 
%         
%     otherwise 
%         
%         error(['No stimulus information available for ' testID]);        
%         
% end % switch testID