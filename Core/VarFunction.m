classdef VarFunction < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = protected)
    functionHandle
    result
    inputVars
    nOutputs
  end
  
  methods
    
    function self = VarFunction(functionHandle,inputVars,nOutputs)
      self.functionHandle    = functionHandle;
      self.inputVars = inputVars;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      
      for k=1:length(self.inputVars)
        self.inputVars{k}.set(varargin{k});
      end

      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(self.inputVars{:});
    end
    
  end
  
end

