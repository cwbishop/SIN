function [varargout] = SIN_UsedListInfo(UsedList, varargin)
%% DESCRIPTION:
%
%   Function to track and return information regarding the used list
%   structure.
%
%   Most methods below load, modify, or save a structure containing
%   information on which lists have been used and with which tests. This
%   structure is described here as the "UserList structure". This is,
%   however, a n N x 2 cell array, where N is the number of lists that have
%   been used. The first column contains the directory name of the list.
%   This is how lists are "tagged". Each list must be in its own directory.
%   If the directories are MOVED and previous calls use an absolute path,
%   then the function will think the same stimuli are different lists.
%   Silly, but it's the most robust way CWB could come up with in a hurry.
%
%   The second column is vertically concatenated character array; each row
%   is a testID describing the test the list was used in. If the list was
%   used in multiple tests, then there will be multiple rows in the second
%   row of the UsedList structure.
%
% INPUT:
%
%   UsedListMat:    string, path to the used list
%
% Parameters:
%
%   'lists':    cell array, each element contains the path to the directory
%               containining the stimulus list. 
%
%   'testID':   string, test description. This is added to the UsedList for
%               ease of tracking.
%
%   'task': one-element cell, which task the user wants to perform. Several tasks are
%           available. 
%
%       User friendly tasks:
%
%           'load': load the specified used list. 
%
%           Returns the used list structure (described above).

%               Ex.: SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'load'}})
%
%           'isused':   Compare the user-specified 'lists' field to the
%                       UsedList mat file. If the element of 'lists' is
%                       found in UsedList, then an integer is returned
%                       corresponding to where that list can be found
%                       within the UsedList. Otherwise, returns 0.
%
%                       Returns an N element integer array, where N is the
%                       number of lists provided in the 'lists' field. 0
%                       indicates that the list has not been used
%                       previously. Non-zero values indicate that the list
%                       has been used and can be found in the corresponding
%                       row of the UsedList structure.
%           
%               Ex.: SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'isused'}}, 'lists', {{'list01' 'list02'}})
%
%           'delete':   delete the UsedList mat file. 
%
%                   No return
%
%               Ex.: SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'delete'}})
%
%           'add':  adds a specific list/testID combination to the UsedList
%                   structure. If the list has already been used, the
%                   testID is appended to the list of testIDs associated
%                   with that list. If the list has NOT been used yet in
%                   any test, then the list and test are added as a new row
%                   to the UsedList structure. 
%
%                   Returns the updated UsedList structure.
%
%               The example below adds list01/02 and appends the testID
%               'bloopers2' to the test list for each.
%
%               Ex.: SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'add'}}, 'lists', {{'list01' 'list02'}}, 'testID', 'bloopers2')
%
%           'removelist':   removes a list and all its associated
%                           information from the UsedList structure. This
%                           may be useful if the user wants to free up a
%                           list for use in other tests. 
%
%                           Returns the updated UsedList structure.
%
%               The following example removes 'list02' from the UsedList.
%               Ex.: SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'removelist'}}, 'lists', {{'list02'}})
%
%           'removetest':   removes a specific test from the specified
%                           list. Note that only a single list is supported
%                           (currently). If the test list in UsedList
%                           structure is empty after removing the test, the
%                           list is also removed. 
%
%                           Returns the updated UsedList structure
%
%               The following example removes testID 'bloopers2' from
%               list02.
%               Ex.:SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'removetest'}}, 'lists', {{'list02'}}, 'testID', 'bloopers2')
%
%           'ntests':   returns the number of tests the specified lists
%                       have been used in, according to the UsedList
%                       structure. 
%
%                       Returns N x 1 array, where N is the number of lists
%                       in 'lists' field. Each element corresponds to the
%                       number of times each list has been used. 
%
%               Ex. SIN_UsedListInfo('C:\Users\cwbishop\Documents\GitHub\SIN\subject_data\1001\usedlist.mat', 'task', {{'ntests'}}, 'lists', {{ 'list01' 'list02' 'list03' 'lk;ajsdf'}})
%
%   Note that 'save' has slightly different input specifications than the
%   other methods. This makes it tricky to use at times, so CWB cautions
%   the user against calling it directly if at all possible. It's designed
%   only to support internal save calls, but can likely be invoked directly
%   if the need arises. 
%
%           'save': saves the UsedList structure. The UsedList structure
%                   must be passed in as the 'lists' parameter. 
%
%                   No return.
%
%               Partial example from code below. If you want to call this
%               directly, then you'll need to spend some time digging
%               through the code. CWB did not intend for this to be used
%               invoked directly by the user.
%
%               Ex: SIN_UsedListInfo(UsedList, 'task', {{'save'}}, 'lists', {listmat});
%
% OUTPUT:
%
%   Outputs vary slightly depending on the method invoked. See 'task' list
%   above. That should describe what is returned in each case. 
%
% Development:
%
% Christopher W. Bishop
%   University of Washington
%   6/14

%% GATHER PARAMETERS
d=varargin2struct(varargin{:});  

%% INPUT CHECKS
%   - Only one task at a time (for now)
%   - If lists is not provided, then create an empty structure
if ~isfield(d, 'task'), d.task = {}; end % create the task array
if numel(d.task)~=1, error('Must have one and only one task'); end 
if ~isfield(d, 'lists') || isempty(d.lists), d.lists={}; end % create empty list

%% LOOP THROUGH TASK(S)
%   Loop is here as a placeholder in case CWB decides to accept task lists
%   instead of single tasks
for t=1:numel(d.task)
    
    % Switch to identify the task to carry out
    switch lower(d.task{t})
        
        case 'ntests'
            
            % Initialize return variable
            ntests = zeros(numel(d.lists), 1);
            
            % Sommersault to load UsedList information
            listmat = SIN_UsedListInfo(UsedList, 'task', {{'load'}}); 
            
            % Determine which elements of 'list' have been used before. 
            isused = SIN_UsedListInfo(listmat, 'task', {{'isused'}}, 'lists', {d.lists});
            
            % Sanity error check
            if numel(isused) ~= numel(d.lists), error('Something wrong here. Dimensions do not match'); end 
                
            % Loop through and figure out how many times the lists have
            % been used
            for m=1:numel(isused)
                
                % Only assign a non-zero number if the list has been used
                % before
                if logical(isused(m))
                    % Recall that each test is listed per row. 
                    ntests(m) = size(listmat{isused(m), 2}, 1); 
                end % if logical(isused(m))
                
            end % for m=1:numel(isused)
            
            % Assign return variable
            varargout{1} = ntests; 
        case 'save'
            
            % Assign filename
            fname = UsedList;
            
            % Assign lists to UsedList variable
            UsedList = d.lists; 
            
            % Issue save command
            save(fname, 'UsedList');        
            
        case 'load'
            
            % Load the used list and return the information in it.
            %   - Extra precaution in loading information
            if ischar(UsedList)
                % Try loading the specified file. If it doesn't exist or
                % fails to load for some reason, return an empty UsedList.
                try
                    l = load(UsedList);            
                    UsedList = l.UsedList;
                catch
                    warning('This might be a stupid try catch statement'); 
                    UsedList = {};
                end % try/catch
                
            elseif iscell(UsedList)
                UsedList = UsedList;  
            else 
                % It must be a new list
                UsedList={};
            end             
            
            % Assign return variable
            varargout{1} = UsedList; 
            
        case 'isused'
            
            % Subroutine determines if the user specified lists have been
            % used at all. If they have been used, an integer index is
            % returned with that describes which row of UserList the list
            % can be found in.
            %
            % If the list does not match, isused returns a 0. 
            
            % Initialize 
            isused = zeros(numel(d.lists), 1);
            
            % IsUsed will retrun an integer index for each element of
            % 'lists' provided by user. If the integer is non-zero, the
            % list has been used.
            % Sommersault to load used list information
            UsedList = SIN_UsedListInfo(UsedList, 'task', {{'load'}}); 
            
            % Compare each element if 'lists' to UsedLists
            for m=1:length(d.lists)
                
                % See if the list has been used
                r = strmatch(d.lists{m}, {UsedList{:,1}}); %#ok<MATCH2>
                
                % Assign integer value if there's a match
                if ~isempty(r)
                    isused(m) = r;
                end % if ~isempty(r)
                
            end % m=1:length(d.lists)
            
            % Return isused variable
            varargout{1} = isused;
            
        case 'delete'
            
            % Delete the file
            delete(UsedList); 
            
        case 'add'
            
            % Sommersault to load used list information
            %   Load as a cell array
            listmat = SIN_UsedListInfo(UsedList, 'task', {{'load'}}); 
            
            % Determine which lists have already been used
            %   Pass in the listmat to save load time (and confusion)
            isused = SIN_UsedListInfo(listmat, 'task', {{'isused'}}, 'lists', {d.lists});             
            
            % Loop through returned isused variable
            %   - If they've been used, then append the test to the second
            %   column of the corresponding row.
            %   - If a list has not been used, then append as a new entry
            %   (new row)
            for m=1:numel(isused)
                
                if isused(m) == 0
                    % If this list has not been used before, then append
                    % the list as a new row along with the associated test
                    % in the second column
                    listmat{end+1, 1} = d.lists{m}; 
                    listmat{end, 2} = d.testID; 
                else
                    % If the list has been used before, then append the
                    % testID to the UsedList information
                    listmat{isused(m), 2} = [strvcat(listmat{isused(m), 2}, d.testID)];
                end % if isused(m) == 0
                
            end % for m=1:numel(isused)
            
            % Save the updated list
            %   - listmat is the updated used list information, so save
            %   that to file
            SIN_UsedListInfo(UsedList, 'task', {{'save'}}, 'lists', {listmat});
            
            % Assign return variable
            %   Return the updated list mat
            varargout{1} = listmat; 
            
        case 'removelist'
            
            % Method to remove lists from the used list. 
            %   - This may be required if a test fails before completion or
            %   if the user wants to free up a list for use in a future
            %   test. 
            
            % Sommersault to load used list information
            %   Load as a cell array
            listmat = SIN_UsedListInfo(UsedList, 'task', {{'load'}}); 
            
            % Determine which lists have already been used
            %   Pass in the listmat to save load time (and confusion)
            isused = SIN_UsedListInfo(listmat, 'task', {{'isused'}}, 'lists', {d.lists});  
            
            % Include all lists by default
            mask = true(size(listmat, 1), 1); 
            
            % Now remove the lists the user wants removed
            mask(isused) = false; 

            % Apply mask
            listmat = [{listmat{mask, 1}}'  {listmat{mask, 2}}']; 
            
            % Save the updated list
            %   - listmat is the updated used list information, so save
            %   that to file
            SIN_UsedListInfo(UsedList, 'task', {{'save'}}, 'lists', {listmat});
            
            % Return the updated list
            varargout{1} = listmat; 
            
        case 'removetest'
            
            % Will remove a specific testID/list combination. This should
            % only be designed to work with a single list/testID
            % combination.
            %   Note: If multiple instances of the same testID are found
            %   with the list, then an error is thrown - we won't know how
            %   to handle this robustly.
            
            % Additional error checks for remove test
            if numel(d.lists)>1, error('Can only remove test from a single list'); end
            
            % Sommersault to load used list information
            %   Load as a cell array
            listmat = SIN_UsedListInfo(UsedList, 'task', {{'load'}}); 
            
            % Determine which lists have already been used
            %   Pass in the listmat to save load time (and confusion)
            isused = SIN_UsedListInfo(listmat, 'task', {{'isused'}}, 'lists', {d.lists});  
            
            % Do not include any used lists by default
            mask = false(size(listmat,1), 1); 
            
            % Just look at the single mask             
            mask(isused) = true;
                        
            % Additional check to make sure we only find the list once
            if numel(find(mask))>1, error('Multiple list entries found. Not currently supported because it is dangerous.'); end
            
            % Find the testID and remove it from the test list
            testind = SIN_UsedListInfo({listmat{mask, 2}}, 'task', {{'isused'}}, 'lists', {{d.testID}});
            
            testmask = false(size(listmat{mask,2}, 1));
            
            % Only change to true if we found a match. 
            if logical(testind)
                testmask(testind) = true;
            end % if logical(testind)
            
            listmat{mask, 2} = listmat{mask, 2}(~testmask, :);
            
            % Save the updated list
            %   - listmat is the updated used list information, so save
            %   that to file
            SIN_UsedListInfo(UsedList, 'task', {{'save'}}, 'lists', {listmat});
            
            % Should we remove the list if we removed the only test it's
            % been used in? Good question. Let's go with "yes" for now.
            if isempty(listmat{mask, 2})
                listmat = SIN_UsedListInfo(UsedList, 'task', {{'removelist'}}, 'lists', {{listmat{mask, 1}}});
            end % if isempty(listmat{mask, 2});
            
            varargout{1} = listmat; 
        otherwise
            error('Invalid task'); 
    end % switch d.task
    
end % for t=1:length(d.task)