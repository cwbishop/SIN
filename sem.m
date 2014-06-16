function s=sem(x, dim)
%% DESCRIPTION:
%
%   Compute standard error of the mean of X. CWB performs this computation
%   frequently and decided to write a function to do it (finally) to save
%   the copy and pasting job he's been doing for half a decade. If DIM is
%   not defined, sem will operate on the first non-singleton dimension. 
%
%   Note that STD is estimated using an unbiased estimator (flag=0). See
%   doc STD for more information.
%
% INPUT:
%   
%   x:      matrix 
%   dim:    integer, dimension across which to calculate SEM. 
%
% OUTPUT:
%
%   s:      SEM estimate. 
%
% Christopher W. Bishop
%   University of Washington
%   2/14

if nargin==1
    dim = find(size(x)~=1,1,'first');
end % if nargin ==1
 
% This occurs when an empty array is passed in. Default to first dimension.
if isempty(dim), dim=1; end 

% Unbiased estimator of standard deviation (divide by n-1). See doc std for
% details. 
s=std(x,0,dim)/sqrt(size(x,dim)); 