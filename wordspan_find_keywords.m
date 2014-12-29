function wordspan_find_keywords(file_list, varargin)
%% DESCRIPTION:
%
%   This will load the provided word span stimulus files and return just
%   the time trace of the keywords within each sentence. This proved useful
%   when trying to calibrate the word span since the carrier phrase does
%   not vary (much) from one sentence to the next.
%
%   We will need to build in some sanity checks on the carrier phrase from
%   sentence to sentence to make sure it hasn't changed fundamentally in
%   some way (e.g., through error or other machinations). 
%
% INPUT:
%
%   file_list:  cell array, paths to word span files. 
%
% Parameters:
%
%   'input_mixer':  Dx1 matrix, where D is the number of channels in the
%                   files to be loaded. For instance, if the files have two
%                   channels but only data present in channel 1, the
%                   input_mixer should be set to [1;0], which will remove
%                   channel two from the mixed input signal. 
%
%   'amplitude_threshold':  amplitude threshold used to identify start of
%                           key word. This should be just above the noise
%                           floor.
%
% OUTPUT:
%
%   XXX
%
% Development:
%
%   None (yet).
%
% Christopher W Bishop
%   University of Washington
%   12/14

%% GATHER INPUT PARAMETERS 
d = varargin2struct(varargin{:});

%% INITIALIZE RETURN VARIABLES
target_words = cell(numel(file_list),1); 

%% PROCESS SENTENCES
for i=1:numel(file_list)
    
    % Load the time series
    [data, fs] = SIN_loaddata(file_list{i}); 
    
    % Apply mixer
    data = data * d.input_mixer; 
    
    % Remove silence from beginning and end. 
    %   This should remove ~1 s from beginning of end. 
    data = threshclipaudio(data, d.amplitude_threshold, 'begin&end'); 
    
    % Extract the carrier phrase
    %   Carrier phrase is approximately 1 s in duration
    carrier_phrase = data(1:fs); 
    
    % Find the first target word
%     word = 
%     target_words{i} = [target_words{i}; 
    
end % for i=1:numel(file_list) 