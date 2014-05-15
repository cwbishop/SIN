function SIN_runTest(testID, varargin)
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
%               randomized order). 
%
% Parameters:
%
%   XXX
%
% OUTPUT:
%
%   XXX
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GET ADDITIONAL PARAMTERS
d=varargin2struct(varargin{:}); 

% For now, only allow a single test
if numel(testID)~=1, error('Incorrect number of testIDs'); end 

% Randomly seed random number generator
rng('shuffle', 'twister');

% Loop through all tests (eventually)
for t=1:length(testID)
    
    % Switch
    %   Each TEST ID has a unique set of instructions. 
    switch testID{t}
        case {'HINT (SNR-50)'}
            
            % Get the HINT options
            opts = d.hint;
            
            % Get available playback lists
            list_id= regexpdir(opts.root, '^List[0-9]{2}', false);
            
            % Shuffle list order, grab first list. We'll use this for
            % playback.
            mask = randperm(length(list_id)); 
            list_id = list_id(mask(1));
            
            % Safety check, although this should never happen. 
            if numel(list_id) ~= 1
                error('something went wrong with list selection');
            end % 
            
            % Now, grab all the wav files
            play_list = regexpdir(list_id{1}, '.wav', false);
            
            % Now, launch HINT (SNR-50)
            portaudio_adaptiveplay(play_list, opts); 
            
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