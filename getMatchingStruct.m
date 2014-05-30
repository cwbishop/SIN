function [index, matched_structs]=getMatchingStruct(structs, varargin)
%% DESCRIPTION:
%
%   Function to find structures that match fieldnames and values provided
%   by the user. This proved useful when trying to identify a specific
%   modifier within a group of modifiers, but can be used to match any
%   field within any set of structures. 
%
% INPUT:
%
%   structs:  cell array, structures to match. 
%
% Parameters:
%
%   Parameter pairs can be any fieldname and its corresponding value.
%
%   If multiple fieldnames must be matched (the more the better, really),
%   then include them as a list of parameters. The function will only
%   return an index if all fields are matched.
%
% OUTPUT:
%
%   index:  integer, index(ices) to matching modifiers. 
%
%   matched_structures:   The matching structures
%
% Christopher W. Bishop
%   University of Washington
%   5/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:}); 

%% FILTERED FIELDNAMES
%   These are the fieldnames the user hopes to match
flds=fieldnames(d);

%% INITIALIZE INDEX
index=false(length(structs), 1); 

%% LOOP THROUGH MODIFIERS
%   - Construct a temporary structure with just the fieldnames that must
%   match from each modifier.
%   - Use comp_struct to determine if the two structures match.
for m=1:length(structs)
    
    % Empty tmodifier
    tmodifier=struct(); 
    
    % Create temporary structure with only filtered fieldnames
    for i=1:length(flds)
        
        % We can only copy over the info if it's a field. 
        if isfield(structs{m}, flds{i})
            tmodifier.(flds{i})=structs{m}.(flds{i}); 
        end % if isfield(modifiers{m}, flds{i})
        
    end % for i=1:length(flds)
    
    % Compare structures 
    df=comp_struct(tmodifier, d, 0);
   
    if isempty(df)
        index(m)=true; 
    end % if isempty(df)
    
end % for m=1:length(modifiers)

% matched_modifiers
matched_structs = structs{index}; 

%% CONVERT INDEX TO INTEGER ARRAY
index=find(index); 