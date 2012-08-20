%% GRO2 Stochastic growth model with irreversible investment
% This is an implementation of the model in Christiano and Fisher (2000).

%% Model's structure
%
% *Response variable* Consumption ($C$), Investment ($I$), Lagrange multiplier
% ($\mu$).
%
% *State variable* Capital stock ($K$), Log of productivity ($Z$).
%
% *Shock* Innovation to productivity ($\epsilon$).
%
% *Parameters* Capital depreciation rate ($\delta$), Discount factor ($\beta$),
% Elasticity of intertemporal substitution ($\tau$), Capital share ($\alpha$),
% Scale parameter ($a$).
%
% *Equilibrium equations*
%
% $$C_{t}: C_{t}+I_{t}=a e^{Z_{t}}K_{t}^{\alpha},$$
%
% $$I_{t}:I_{t}\ge 0 \quad \perp \quad C_{t}^{-\tau}+\mu_{t}\ge 0,$$
%
% $$\mu_{t}: \mu_{t}+\beta\mathrm{E}_{t}\left[a \alpha e^{Z_{t+1}}K_{t+1}^{\alpha-1}C_{t+1}^{-\tau}-\mu_{t+1}\left(1-\delta\right)\right]=0.$$
%
% *Transition equations*
%
% $$K_{t}: K_{t}=\left(1-\delta\right)K_{t-1}+I_{t-1},$$
%
% $$Z_{t}: Z_{t}=\rho Z_{t-1}+\epsilon_{t}.$$

%% Writing the model
% The model is defined in a yaml file: <gro2.yaml>.

%% Pack model structure
% Mean and standard deviation of the shocks
Mu                = 0;
sigma             = 0.04;

%%
model = recsmodelinit('gro2.yaml',...
                      struct('Mu',Mu,'Sigma',sigma^2,'order',7));

%%
% This command creates a Matlab file, <gro2model.html gro2model.m>, containing
% the definition the model and all its Jacobians from the human readable file
% <gro2.yaml>.

%% Find deterministic steady-state
a             = model.params(1);
delta         = model.params(3);
[sss,xss,zss] = recsSS(model,[1 0],[a-delta 0 0])

%% Define approximation space
% Degree of approximation
order         = [14 14];                                 
%%
% Limits of the state space
smin          = [0.47*sss(1)  min(model.e)*3.5];
smax          = [1.72*sss(1)  max(model.e)*3.5];
%%
% Function space
interp.fspace = fundefn('spli',order,smin,smax);           
%%
% State collocation nodes
s             = gridmake(funnode(interp.fspace));

%% Find a first guess through the perfect foresight solution
[interp,x] = recsFirstGuess(interp,model,s,sss,xss,50);

%% Define options
options = struct('reesolver','krylov');

%% Solve for rational expectations
interp = recsSolveREE(interp,model,s,x,options);

%% Simulate the model
[~,~,~,~,stat] = recsSimul(model,interp,sss(ones(1000,1),:),200);
subplot(2,3,1)
xlabel('Capital stock')
ylabel('Frequency')
subplot(2,3,2)
xlabel('Log of productivity')
ylabel('Frequency')
subplot(2,3,3)
xlabel('Consumption')
ylabel('Frequency')
subplot(2,3,4)
xlabel('Investment')
ylabel('Frequency')
subplot(2,3,5)
xlabel('Lagrange multiplier')
ylabel('Frequency')

%% References
%
% Christiano, L.J. and Fisher, J.D.M. (2000). Algorithms for solving dynamic
% models with occasionally binding constraints. _Journal of Economic Dynamics
% and Control_, 24(8), 1179-1232.

%%
% Copyright (C) 2011-2012 Christophe Gouel
%
% Licensed under the Expat license, see <LICENSE.txt>