for i=1:numel(bad_mlst_files)
    
    % Need to get the original file name for the conversion below
    [PATHSTR, NAME, EXT] = fileparts(bad_mlst_files{i}); 
    NAME = NAME(1:findstr(NAME, ';bandpass;')-1); 
    
    orig_file = fullfile(PATHSTR, [NAME EXT]); 
    
    cmd = ['ffmpeg -y -i "'...
    orig_file '" -i "' strrep(bad_mlst_files{i}, '.mp4', '.wav')...
                    '" -map 0:0 -map 1 "' bad_mlst_files{i} '"'];

    system(cmd, '-echo'); 
end % for i=:numel(bad_mlst_files)