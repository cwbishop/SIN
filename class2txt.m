function description = class2txt(data, varargin)
%% DESCRIPTION:
%
%   Function to convert various classes to a descriptive text string.
%   Designed to be used in combination with Selection_GUI and SIN_select.
%
% INPUT:
%
%   data:   data to create a descriptive string for. Should more or less
%           work with the following classes
%               - char (duh)
%               - cell
%               - single/double
%               - struct
%
% Parameters:
%
%   None (yet)
%
% OUTPUT:
%
%   txt:    cell array, text descriptions for each element of data.
%
% Development:
%
% Christopher W Bishop
%   University of Washington
%   10/14

%% GET PARAMETERS
d=varargin2struct(varargin{:});

description = {}; 
switch class(data)
    
    case 'struct'
        
        % Convert structures to descriptive text
        for i=1:numel(data)
            tdescrip = []; 
            % Get field names
            
            % Loop through fields, convert each to string, add to growing
            % description.
            flds = fieldnames(data); 
            for j=1:numel(flds)
                fldtxt = class2txt(data(i).(flds{j}));
                tdescrip = deblank(char(tdescrip, [flds{j} ': ' fldtxt{1}]));
            end % for j=1:numel(flds)
            
            % Add to growing description cell array. 
            description{end+1} = tdescrip;  %#ok<AGROW>
            
        end % for i=1:numel(struct)
    
    case 'cell'
        
        % Loop through cell and use recursive calls to convert to text
        for i=1:numel(data)
            description{end+1} = class2txt(data{i});  %#ok<*AGROW>
        end % for i=1:
        
    case {'single' 'double'}
        
        % Convert singles/doubles to strings
        description{end+1} = num2str(data); 
        
    case 'char'
        
        % We don't do anything for character class
        description{end+1} = data; 
        
    otherwise
        error('Unsupported class'); 
end % switch