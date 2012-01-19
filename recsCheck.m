function [err,discrepancy] = recsCheck(model,s,x,z,e,snext,xnext)
% RECSCHECK Checks analytical derivatives against numerical ones
%
% When the model file is not generated automatically by dolo-recs, RECSCHECK is
% useful to verify that the hand-coded Jacobians are good.
%
% RECSCHECK(MODEL,S,X,Z) checks analytical derivatives on the point defined by
% the 1-by-d vector of state variables, S, the 1-by-m vector of response
% variables, X, and the 1-by-p vector of expectations variables, Z. In this
% default case, RECSCHECK tests the derivatives for shocks at their mean level;
% for next-period state variables equal to S; and for next-period response
% variables equal to X.
%
% RECSCHECK(MODEL,S,X,Z,E) checks derivatives for the value of the shocks
% supplied in E.
%
% RECSCHECK(MODEL,S,X,Z,E,SNEXT) checks derivatives for the value of next-period
% state variables supplied in SNEXT.
%
% RECSCHECK(MODEL,S,X,Z,E,SNEXT,XNEXT) checks derivatives for the value of
% next-period response variables supplied in XNEXT.
%
% ERR = RECSCHECK(MODEL,S,X,Z,...) returns ERR, a 1x9 vector containing the maximal
% differences between analytical and numerical derivatives.
%
% [ERR,DISCREPANCY] = RECSCHECK(MODEL,S,X,Z,...) returns DISCREPANCY, a structure
% containing the detailed differences between analytical and numerical derivatives.
%
% See also RECSMODELINIT.

% Copyright (C) 2011 Christophe Gouel
% Licensed under the Expat license, see LICENSE.txt

if nargin < 7 || isempty(xnext), xnext = x;                end
if nargin < 6 || isempty(snext), snext = s;                end
if nargin < 5 || isempty(e)    , e     = model.w'*model.e; end

if size(s,1)~=1 || size(x,1)~=1 || size(e,1)~=1 || size(snext,1)~=1 || size(xnext,1)~=1
  error('Derivatives can only be check at one location, not on a grid');
end

params = model.params;
if isa(model.func,'char')
  func = str2func(model.func);
elseif isa(model.func,'function_handle')
  func = model.func;
else
  error('model.func must be either a string or a function handle')
end

outputF  = struct('F',1,'Js',0,'Jx',0,'Jz',0,'Jsn',0,'Jxn',0,'hmult',0);
outputJ  = struct('F',0,'Js',1,'Jx',1,'Jz',1,'Jsn',1,'Jxn',1,'hmult',0);

% Analytical derivatives
[~,fs,fx,fz] = func('f',s,x,z,[],[],[],params,outputJ);

[~,gs,gx] = func('g',s,x,[],e,[],[],params,outputJ);

[~,hs,hx,hsnext,hxnext] = func('h',s,x,[],e,snext,xnext,params,outputJ);

% Numerical derivatives
if ~isempty(fs), fsnum = numjac(@(S) func('f',S,x,z,[],[],[],params,outputF),s); end
fxnum = numjac(@(X) func('f',s,X,z,[],[],[],params,outputF),x);
fznum = numjac(@(Z) func('f',s,x,Z,[],[],[],params,outputF),z);

if ~isempty(gs), gsnum = numjac(@(S) func('g',S,x,[],e,[],[],params,outputF),s); end
gxnum = numjac(@(X) func('g',s,X,[],e,[],[],params,outputF),x);

if ~isempty(hs)
  hsnum = numjac(@(S) func('h',S,x,[],e,snext,xnext,params,outputF),s);
end
hxnum = numjac(@(X) func('h',s,X,[],e,snext,xnext,params,outputF),x);
hsnextnum = numjac(@(SNEXT) func('h',s,x,[],e,SNEXT,xnext,params,outputF),snext);
hxnextnum = numjac(@(XNEXT) func('h',s,x,[],e,snext,XNEXT,params,outputF),xnext);

% Error
if ~isempty(fs)
  err = norm(fs(:)-fsnum(:),inf);
else
  err = NaN;
end
err = [err norm(fx(:)-fxnum(:),inf)];
err = [err norm(fz(:)-fznum(:),inf)];

if ~isempty(gs)
  err = [err norm(gs(:)-gsnum(:),inf)];
else
  err = [err NaN];
end
err = [err norm(gx(:)-gxnum(:),inf)];

if ~isempty(hs)
  err = [err norm(hs(:)-hsnum(:),inf)];
else
  err = [err NaN];
end
err = [err norm(hx(:)-hxnum(:),inf)];
err = [err norm(hsnext(:)-hsnextnum(:),inf)];
err = [err norm(hxnext(:)-hxnextnum(:),inf)];

if max(err)>1.e-4
   disp('Possible Error in Derivatives')
   disp('Discrepancies in derivatives = ')
   fprintf(1,'fs       fx       fz       gs       gx       hs       hx       hsnext   hxnext\n');
   fprintf(1,'%1.1e %1.1e %1.1e %1.1e %1.1e %1.1e %1.1e %1.1e %1.1e\n',err);
end

discrepancy    = struct(...
    'fx', reshape(fx,size(fxnum))-fxnum, ...
    'fz', reshape(fz,size(fznum))-fznum, ...
    'gx', reshape(gx,size(gxnum))-gxnum, ...
    'hx', reshape(hx,size(hxnum))-hxnum, ...
    'hsnext', reshape(hsnext,size(hsnextnum))-hsnextnum, ...
    'hxnext', reshape(hxnext,size(hxnextnum))-hxnextnum);
