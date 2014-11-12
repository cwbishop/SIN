function git_is_current(repo)
%% DESCRIPTION:
%
%   Function determines if a repository is fully up to date with all
%   changes committed or not.
%
% INPUT:
%
%   repo:   full path to repo. (default = pwd) 
%
% OUTPUT:
%
%   is_current: bool, returns true if the git repository is up to date.
%               False otherwise.
%
% Christopher W Bishop
%   University of Washington
%   11/14

% Set default directory
if ~exist('repo', 'var') || isempty(repo), repo = pwd; end
if ~isequal(name, '.git'), repo = [repo filesep '.git']; end

% Get status
[status, results] = system('git '

% Command failed
if status, error(['Could not issue command for ' repo]); end