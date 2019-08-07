%% OpenOCL Open Optimal Control Library
% Software for optimal control, trajectory optimization, and
% model predictive control.
%
% Web: <a href="https://openocl.org/">https://openocl.org/</a> 
% API docs: <a href="https://openocl.org/api-docs/">https://openocl.org/api-docs/</a>
%
%% Get started
%
% Run an example with:
%   
%   <a href="matlab:ocl.examples.cartpole">ocl.examples.cartpole</a>
% 
% Get a list of all examples:
%
%   <a href="matlab:help ocl.examples">help ocl.examples</a>
%
% Look at example code:
%
%   <a href="matlab:open ocl.examples.cartpole">open ocl.examples.cartpole</a>
%
%% List of optimal control examples
% 
% * <a href="matlab:open ocl.examples.ballandbeam">ocl.examples.ballandbeam</a>
% * <a href="matlab:open ocl.examples.bouncingball">ocl.examples.bouncingball</a> (two-stage)
% * <a href="matlab:open ocl.examples.cartpole">ocl.examples.cartpole</a>
% * <a href="matlab:open ocl.examples.pendulum">ocl.examples.pendulum</a>
% * <a href="matlab:open ocl.examples.racecar">ocl.examples.racecar</a>
% * <a href="matlab:open ocl.examples.vanderpol">ocl.examples.vanderpol</a>
%
%% List of simulation examples
%
% * <a href="matlab:open ocl.examples.bouncingball_sim">ocl.examples.bouncingball_sim</a> (multi-stage)
% * <a href="matlab:open ocl.examples.pendulum_sim">ocl.examples.pendulum_sim</a> 
%
%% Copyright notice
%
% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
% Get the license text from:  
%
% <https://openocl.org/bsd-3-clause/>

function ocl
  ocl.utils.startup
