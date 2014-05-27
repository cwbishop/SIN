function [MASK, BOUNDS]=SIN_maskdomain(DOMAIN, BOUNDS)
%% DESCRIPTION:
%
%   Function returns a logical mask of the domain within the specified
%   bounds. This is something CWB had to do repeatedly when computing SNR
%   in frequency and time domains. CWB preferred to have one central
%   function do the masking so the masking is always done the same way and
%   it's easy to introduce the operation into new functions.
%
%   Note: When using AA_maskdomain to estimate pre and post stim baseline
%   periods, there may be a single point of overlap between the two
%   (typically at 0 ms). If this is a problem, then adjust the BOUNDs
%   accordingly. 
%
%   Note: The window estimation here is liberal, meaning that if exact
%   values are not found, the window will be expanded to encompass the
%   missing point.
%
% INPUT:
%
%   DOMAIN:     Nx1 or 1xN double array, data to be masked. This can be any
%               type of data, but is often the domain of a function (e.g.,
%               time or frequency).
%   BOUNDS:     Two element array defining how to bound the domain.
%
% OUTPUT:
%
%   MASK:       N element logical mask. This can be used to mask the DOMAIN
%   BOUNDS:     Two element array defining the actual bounds of the
%               original domain. Note that this may differ from the
%               requested bounds if an exact value match is not found.  
%
% Christopher W. Bishop
%   University of Washington
%   2/14

%% INPUT CHECKS
%   If the DOMAIN or BOUNDS are not the correct size, throw an error
if max(size(DOMAIN))<2, error('Invalid DOMAIN.'); end
if numel(BOUNDS)==1, BOUNDS=[BOUNDS BOUNDS]; end   % allow for single frequency masking.
if length(BOUNDS)~=2 || min(size(BOUNDS))>1, error('Invalid BOUNDS.'); end

MASK=(DOMAIN>=BOUNDS(1) & DOMAIN<=BOUNDS(2));

BOUNDS=[DOMAIN(find(MASK==1, 1, 'first')) DOMAIN(find(MASK==1, 1, 'last'))];