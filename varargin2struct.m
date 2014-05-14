function d=varargin2struct(varargin)
%% DESCRIPTION:
%
%   This function massages input parameter pairs (e.g., 'dbStep', [1 23])
%   into a structure with the appropriate field names. 
%
%   Function will also handle various input types, such as pairing
%   structures and input parameters. This proved useful for the Speech In
%   Noise (SIN) suite CWB wrote.
%
% INPUT:
%
%   varargin:   parameters and structures
%
% OUTPUT:
%
%   d:  a single structure with all fieldnames set. 
%
% Christopher W. Bishop
%   University of Washington
%   5/14

% Flag for while loop
keep_running=true; 
n=1; % counter used below. CWB hates this kind of thing, but can't think of a better way to do it quickly

% Parameter/value pairs
parvals={};

% Loop through all of varargin. Do different things for different types of
% information. At time of writing, this will deal with structures and
% paramter/value pairs
while keep_running
    
    % Have we reached the end of the input variables?
    %   If so, break out of the while loop
    if n > nargin
        break
    end % if n > nargin
    
    % Copy to temp variable
    t=varargin{n};
    
    % Process differently for each 
    if isstruct(varargin{n})
        
        flds=fieldnames(t);
        
        % Loop through all fields, add them to parvals
        for i=1:length(flds)
            
            parvals{end+1}=flds{i};
            
            % Need special instructions for cells
            if iscell(t.(flds{i}))
                parvals{end+1}={t.(flds{i})};
            else
                parvals{end+1}=t.(flds{i});
            end % if iscell
            
        end % for i=1:length(flds)
        
        n=n+1; 
        
    elseif ischar(t)
        
        % Get the parameter name
        parvals{end+1}=t;
        
        % Set the parameter value
        parvals{end+1}=varargin{n+1};
        
        % Increment counter
        n=n+2; % skip over the parameter value
        
    end % 
    
end % while

%% CONVERT TO STRUCTURE
d=struct(parvals{:}); 
