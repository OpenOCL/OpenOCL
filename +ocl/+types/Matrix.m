% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Matrix < ocl.types.Structure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    msize
  end
  
  methods
    
    function self = Matrix(size)
      % OclMatrix(size)
      self.msize = size;
    end
    function [N,M,K] = size(self)
      s = self.msize;
      if nargout>1
        N = s(1);
        M = s(2);
        K = 1;
      else
        N = s;
      end
    end
  end
end
