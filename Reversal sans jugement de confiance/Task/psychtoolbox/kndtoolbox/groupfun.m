function [R,uG,XG,n] = groupfun(X,G,varargin)
%GROUPFUN - Perform computation according grouping variables
%   [R,uG] = groupfun(X,G,fun)
%   e.g. groupfun(randn(100,1),round(rand(100,1)),'mean')
%   e.g. 
%
%   [R,uG,XG,n] = ... also outputs:
%       uG: the list of the unique values for groups
%       XG: a cell array of X values split into groups
%        n: number of matches for each group
%
%   Example
%       >> groupfun
%
%   See also:

% Author: K. N'Diaye (kndiaye01<at>yahoo.fr)
% Copyright (C) 2009
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by  the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version: http://www.gnu.org/copyleft/gpl.html
%
% ----------------------------- Script History ---------------------------------
% KND  2009-11-19 Creation
%
% ----------------------------- Script History ---------------------------------
s=size(X);
if size(G,1) ~= s(1) 
    error('The number of line of X must match the number of lines in G')
end
if prod(s)==max(s) & numel(G)==max(s) & s(1)==1
    % Transpose
    G=G';
    X=X';
    s=size(X);
end
    if nargin<3
    %default: mean
    varargin = {'mean' 1};
end
[g,uG] = unicize_groups(G);
ng = size(uG,1);
n=zeros(ng,1);
R=[];
for i=1:ng
    if isnan(uG(i))
        r=X(g==i,:);
    else
        r = feval(varargin{1},X(g==i,:),varargin{2:end});
        if numel(r) < sum(s(2:end)) % && numel(r)~= prod(size(r))  [this was obviously true!]
            error('Wrong output of function %s (maybe 1-line vector issue with sum and the like)', varargin{1});
        end
    end
    R(i,:) = r;
    if nargout>2 || nargout==0
        n(i,1) = sum(g==i);
        s(1)= n(i);
        XG{i,1} = reshape(X(g==i,:),s);
    end
end
s(1)=ng;
R=reshape(R,s);
if nargout==0
<<<<<<< .mine
   disp([ 'Grouping by ' inputname(2) ':']);
   disp(uG) 
   disp(n)
=======
   disp('Grouping: Result');
   for i=1:ng
       disp([ sprintf2(uG(i)) ' (n=' sprintf2(n(i)) '): ' sprintf2(R(i,:)) ]);
   end
>>>>>>> .r684
   if any(isnan(uG))
       disp('For NaN''s:')
       disp(feval(varargin{1},X(isnan(uG(g)),:),varargin{2:end}));
   end
end
return

% Unicize groups
function [g,uG] = unicize_groups(G)
[uG,ignore,g]  = unique(G, 'rows');
return