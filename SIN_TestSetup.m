opts=SIN_TestSetup(testID)
%
% Should also spit back a testlist. This is needed for SIN_GUI
opts=struct();

switch testID
    case 'default'
        
        % Set some default values, like device settings, that will be used
        % by multiple tests. 
    case 'HINT (SNR-50)'
        
    otherwise
        error('unknown testID')
end % switch 

