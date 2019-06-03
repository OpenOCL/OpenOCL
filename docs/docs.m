%% OpenOCL Open Optimal Control Library
% Software for optimal control, trajectory optimization, and
% model predictive control.
%
% Web: <https://openocl.org/>
%
% API docs: <https://openocl.org/api-docs/>
%
%% Get help from the command line
%
% help ocl
%
%% Get started
%
% Run an example with:
%   
%   ocl.examples.cartpole
% 
% Get a list of all examples:
%
%   help ocl.examples
%
% Look at example code:
%
%   open ocl.examples.cartpole
% 
%% List of optimal control examples
% 
% * ocl.examples.vanderpol
% * ocl.examples.ballandbeam
% * ocl.examples.pendulum
% * ocl.examples.racecar
% * ocl.examples.cartpole
% * ocl.examples.bouncingball (multi-phase)
%
%% List of simulation examples
%
% * ocl.examples.pendulum_sim
% * ocl.examples.bouncingball_sim (multi-phase)
%
%% List of classes
%
% * ocl.System (OclSystem)
% * ocl.OCP (OclOCP)
% * ocl.Options (OclOptions)
% * ocl.Solver (OclSolver)
%
%% List of functions
%
% * ocl.plot
% * ocl.stairs
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
%
%% Cartpole example
% 
ocl.examples.cartpole(20);
%
%% Multi-phase bouncing ball example
% 
ocl.examples.bouncingball;
