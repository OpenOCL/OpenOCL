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
      
      ins = cell(1,length(self.inputs));
      for k=1:length(ins)
        ins{k} = Var(self.inputs{k},varargin{k});
      end
      
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(ins{:});
    end
    
  end
  
end

