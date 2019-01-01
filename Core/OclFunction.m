classdef OclFunction < handle  
  properties (Access = public)
    functionHandle
    nInputs
    nOutputs
  end
  
  methods
    
    function self = OclFunction(functionHandle,nInputs,nOutputs)
      self.fh = functionHandle;
      self.nInputs = nInputs;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      [varargout{:}] = self.functionHandle(varargin{:});
    end
  end
end

