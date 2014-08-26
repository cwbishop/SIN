vid = av.vid;
whichScreen=max(Screen('Screens'));
[window,screenRect] = Screen('OpenWindow',whichScreen);
d.window = window;
% textures = cell(numel(X), 1); % preallocate
% Map to texture in window
tindex = nan(size(vid,4),1); % preallocate, set to NaN
tic
for n=1:size(vid,4)
    tindex(n) = Screen( 'MakeTexture', d.window, vid(:,:,:,n) );
end % for n=1:
toc
% Now copy tindex over to a cell array
% textures = tindex;
% runtime = GetSecs - start

Screen('CloseAll'); 