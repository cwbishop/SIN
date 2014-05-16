function SIN_runTest(testID, d, varargin)
%% DESCRIPTION:
%
%   Master control function to run various tests associated with SIN. The
%   basic idea is to pass the function a unique test identifier (CWB is
%   thinking a string) that can be used to execute a specific set of
%   instructions. The upshot of this approach is that the same test can be
%   executed with ease from the commandline or via a GUI. 
%
% INPUT:
%
%   testID:     cell containing the test ID. CWB opted to used a cell here
%               in case he later wants to use a test list (meaning, running
%               a sequence of tests in a specific order - perhaps a
%               randomized order). Alternatively, testID can be a string.
%               This will be automatically converted to a cell within the
%               function.           
%
%   d:  SIN structure. See SIN_defaults. SIN_defaults will not be loaded if
%       d is omitted. 
%
% Parameters:
%
%   'play_list':    cell array, stimulus play_list.  
%
%   'randomize':    bool, randomize play_list. (true | false ). Must be set
%                   in SIN_defaults. 
%
% OUTPUT:
%
%   None (yet) 
%
% Development:
%
%   1) Complete ANL test administration.   
%
%   2) Make randomization more modular (so we can use for multiple tests,
%   not just HINT).
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GET ADDITIONAL PARAMTERS
%   o is a structure with additional options set by user
o=varargin2struct(varargin{:}); 

% Convert char to cell
if ischar(testID)
    testID={testID};
end % if ischar

% Input checks
if numel(testID)~=1, error('Incorrect number of testIDs'); end 
if ~isfield(o, 'play_list') || isempty(o.play_list), error('No play list specified'); end 

% Grab variables we need to run our tests 
play_list=o.play_list;

clear o; % clear o to remove temptation 

% Loop through all tests (eventually)
for t=1:length(testID)
    
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        case {'HINT (SNR-50)'}
            
            % Get the HINT options
            opts = d.hint;
            
            if opts.randomize
    
                % Seed random number generator
                rng('shuffle', 'twister');
    
                play_list={play_list{randperm(length(play_list))}}; 
    
            end % if o.randomize
            
            
            
            % Now, launch HINT (SNR-50)
            r = portaudio_adaptiveplay(play_list, opts); 
            
        case {'ANL'}
        case {'PPT'}
        case {'MLST'}
        case {'Hagerman'}
        case {'ALL (Random)'}
            % Run all tests in a random order
            error('Not implemented'); 
            
        otherwise
            
            error(['Unknown test ID: ' testID{t}]); 
            
    end % switch/otherwise
end % for t=1:length(testID)