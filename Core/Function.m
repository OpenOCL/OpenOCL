classdef Function < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = public)
    functionHandle
    result
    inputs
    nOutputs
  end
  
  methods
    
    function self = Function(functionHandle,inputs,nOutputs)
      self.functionHandle    = functionHandle;
      self.inputs = inputs;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(varargin{:});
    end
    
  end
  
end

