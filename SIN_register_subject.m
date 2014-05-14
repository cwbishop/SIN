function [status, e]=SIN_register_subject(sid, varargin)
%% DESCRIPTION:
%
%   Function that will (hopefully) handle subject registration cleanly.
%
%   Slated features include the following
%
%       - Determine if subject already exists. If so, don't do anything.
%       - If subject does not exist, create subject directory structure.
%
% INPUT:
%
%   sid:    string, subject ID
%
% Parameters:
%
%   'register_tasks':cell array of tasks to perform, in order they should be
%               performed. At time of writing, there's only one task to do
%               ('create'), but CWB has vague plans to expand upon this. So
%               the option is here. (default='create')
%
%                   'create':   create subject and test directories
%
%                   'validateID':   determine if subject ID conforms to a
%                                   preset format. 
%
% OUTPUT:
%
%   status: bool, true if all register_tasks were completed successfully.
%           False if *any* of the register tasks failed.
%
%   e:      string, error message. Useful for error feedback in SIN gui. 
%
% Development:
%
%   1. Make status return variable more informative. 
%
%   2. Generalize "e" return to be a generalized message. Status will
%   determine if it's an error (status == 0) or something good (status==1).
%   Can be coupled with SIN.m to create color coded feedback in terminal. 
%
% Christopher W. Bishop
%   University of Washington 
%   5/14

%% GATHER ADDITIONAL PARAMETERS
d=varargin2struct(varargin{:}); 

% Default task
%   A place holder for now until CWB's brain can wrap around other
%   potential uses for this. 
if ~isfield(d, 'register_tasks') || isempty(d.register_tasks), d.register_tasks={'create'}; end

% Initialize error message to nothing
e=[];
for t=1:numel(d.register_tasks)
    switch d.register_tasks{t}
        
        case {'create'}
            
            % Sommersault to validate subject ID
            if ~SIN_register_subject(sid, 'register_tasks', {{'validateID'}})
                e=errmsg('validateID');
                status=false;
                return;
            end % if ~SIN_register_subject ...
            
            % See if we have the root directory information. If we don't then get it
            % from SIN_defaults.
            %   
            % Also need the test list information.
            try 
                d.root;
                testlist={d.testlist.name}; 
            catch
                d=SIN_defaults; 
                testlist={d.testlist.name}; 
            end % try/catch

            %% CHECK TO SEE IF SUBJECT DIRECTORY EXISTS
            if exist(fullfile(d.root, 'subject_data', sid), 'dir')
                status=false;
                e=errmsg([sid ' exists.']);
                return;
            end % if exist
            
            %% MAKE SUBJECT DIRECTORY
            status=mkdir(fullfile(d.root, 'subject_data', sid));

            %% MAKE TEST DIRECTORIES
            %   For now, just create directories 
            for i=1:length(testlist)
                
                % Check for errors making test directories 
                if ~mkdir(fullfile(d.root, 'subject_data', sid, testlist{i})); 
                    status=false;
                end % if ~mkdir(...
                
            end % for i=1:length(testlist)
            
            % Create error message if necessary
            if ~status
                e=errmsg(d.register_tasks{t});
                return;
            end % if 
            
        case {'validateID'}
            % Validate that the subject ID conforms to some specifid
            % format. 
            %
            % At time of writing, this will take the form of [1
            % 2][0-9][0-9][0-9]. The first digit specifies the test site
            % and the remaining three digits are subject specific. 
            %
            % For more information on how to set this up properly, see
            %
            %   http://www.mathworks.com/help/matlab/ref/regexp.html
            startIndex=regexp(sid, '^[1 2][0-9]{3}$');  
            
            % If there's one and only one match, then we're golden.
            % Otherwise, something stupid happened.
            if numel(startIndex)==1
                status=true;
            else 
                
                % Set status to false
                status=false; 
                
                % Generate error message 
                e=errmsg(d.register_tasks{t});
                
                return; 
            end % 
            
        otherwise 
            
            error(['Unknown registration task: ' d.register_tasks{t}]); 
            
    end % switch
    
end % for t=1:numel(d.register_tasks)

function [msg]=errmsg(str, varargin)
%% DESCRIPTION:
%
%   Function to generate generic error message for SIN_register_subject.m.
%
% INPUT:
%
%   str:    string, error message to append to generic form. 
%
% OUTPUT:
%
%   msg:    error message
%
% Development:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington
%   5/14

msg=[mfilename ': ' str];
