function audio_files = concatenate_lists(audio_files)
%% DESCRIPTION:
%
%   This function converts a LIST x N cell array to a (LIST x N) x 1 cell
%   array. This proved useful when converting the output from SIN_stiminfo
%   to a single file list.
%
% INPUT:
%
%   audio_files:    LIST x N cell array, where N is the number of file
%                   names and LISTS is the number of lists.
%
% OUTPUT:
%
%   audio_files:    (LIST x N) x 1 cell array of file names
%
% Christopher W Bishop
%   University of Washington
%   10/14

taudio = {};
for i=1:numel(audio_files)
    for k=1:numel(audio_files{i})
        taudio{end+1} = audio_files{i}{k};
    end
end

audio_files = taudio'; 
