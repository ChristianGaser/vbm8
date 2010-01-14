function h = rician_MLestimate(ima)
% ML estimation of rician noise in the image background
%
% This is a modified version from
%
%   Author: Santiago Aja Fernandez
%   LOCAL STATISTICS TOOLBOX
%
%   Modified: Feb 01 2008
%_______________________________________________________________________
% Christian Gaser
% $Id: rician_MLestimate.m 115 2009-03-10 10:40:12Z gaser $

% find indexes, where image is > 0
% to remove slices, where zeros were padded
sz = size(ima);
xind = []; yind = []; zind = [];
for x = 1:sz(1)
  ind = find(ima(x,:,:)>0);
  if ~isempty(ind)
    xind = [xind x];
  end
end
for y = 1:sz(2)
  ind = find(ima(:,y,:)>0);
  if ~isempty(ind)
    yind = [yind y];
  end
end
for z = 1:sz(3)
  ind = find(ima(:,:,z)>0);
  if ~isempty(ind)
    zind = [zind z];
  end
end

k = 3;
A = (convn(ima(xind,yind,zind),ones(k,k,k),'same')/k^3);
h = 0.7979*moda(A,1000);

function m = moda(u,N)
% MODA   Mode of a distribution
%
%    m=MODE(u,N) calculates the mode of the set of data "u" using the histogram.
%    To avoid outliers, for the calculation are only taken into account those
%    values in [mean-2sigma, mean+2sigma];
%
%    INPUT:
%
%	- u (set of data)
%       - N: Number of points for the histogram. If N=0 then 5000 points are
%            considered
%
%   Author: Santiago Aja Fernandez
%   LOCAL STATISTICS TOOLBOX
%
%   Modified: Feb 01 2008
%

if N==0
	N = 1000;
end

u = double(u(:));

M1 = mean(u);
V1 = std(u);
C2 = u(u<=(M1+2*V1));
[h,x] = hist(C2,N);
[M,M2] = max(h);

% if first entry in histogram has maxima it is very likely that images
% was segmented (skull stripped)
if M2==1
  m = 0;
else
  m = x(M2);
end

