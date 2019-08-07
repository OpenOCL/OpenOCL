% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [nFails] = log(suffix)
 nFails = ocl.tests.run.core(1,1,suffix);