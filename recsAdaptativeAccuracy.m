function res = recsAdaptativeAccuracy(interp,model,snodes,options)
% RECSADAPTATIVEACCURACY 

% Copyright (C) 2011-2013 Christophe Gouel
% Licensed under the Expat license, see LICENSE.txt

%% Initialization
defaultopt = struct('simulmethod','solve',...
                    'stat'       ,0);
if nargin <=3
  options = struct(defaultopt); 
else
  warning('off','catstruct:DuplicatesFound')
  options = catstruct(options,defaultopt);
end

h         = model.functions.h;
ixforward = model.infos.ixforward;
params    = model.params

cx     = interp.cx;
fspace = interp.fspace;

%%
res = zeros(size(snodes,2),1);             
for i=1:size(snodes,2)
  MidPoints = blktridiag(1,1,0,length(snodes{i}))/2;
  snodei = (snodes{i}'*MidPoints(:,1:end-1))';
  
  snodesnew    = snodes;
  snodesnew{i} = snodei;
  s            = gridmake(snodesnew);
  [~,x]  = recsSimul(model,interp,s,1,[],options);
  Phi    = funbasx(interp.fspace,s);
  R      = recsResidual(s,x,h,params,cx,fspace,'resapprox',Phi,ixforward,false);
  res(i) = norm(R,Inf);
end