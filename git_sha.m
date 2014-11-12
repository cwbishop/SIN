function [sha, status] = git_sha(repo)
%% DESCRIPTION:
%
%   This function returns the SHA key for a GIT repository using the
%   git.exe. 
%
%   Note that git.exe must be in the system path for this to work properly.
%
% INPUT:
%
%   repo:   path to GIT repository directory. Full path required since
%           command is executed at Windoze command line.
%
% OUTPUT:
%
%   sha:    SHA key of git repo. 
%
% Christopher W Bishop
%   University of Washington
%   11/14

% Set default directory
if ~exist('repo', 'var') || isempty(repo), repo = pwd; end

% Are we looking at the git subdirectory?
%   If not, then append the .git directory. That's where the command must
%   be executed. 
%
%   See http://stackoverflow.com/questions/3769137/use-git-log-command-in-another-folder
%
%   That's what CWB used as a reference. 
[pathstr, name, ext] = fileparts(repo); 

if ~isequal(name, '.git'), repo = [repo filesep '.git']; end

% Store current working directory.
command = ['git --git-dir "' repo '" rev-parse HEAD'];

% Execute command
[status, sha] = system(command); 

% Throw an error if we could not retrieve the repository SHA key. 
if ~status, error(['Could not retrive SHA key for ' repo]); end