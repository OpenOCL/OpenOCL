% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclFunction < handle  
  properties (Access = public)
    obj
    functionHandle
    inputSizes
    nOutputs
  end
  
  methods
    
    function self = OclFunction(obj,functionHandle,inputSizes,nOutputs)
      self.obj = obj;
      self.functionHandle = functionHandle;
      self.inputSizes = inputSizes;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(self.nOutputs,1);
      [varargout{:}] = self.functionHandle(self.obj,varargin{:});
    end
  end
end

