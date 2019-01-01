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
      self.fh = functionHandle;
      self.inputSizes = inputSizes;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      [varargout{:}] = self.functionHandle(self.obj,varargin{:});
    end
  end
end

