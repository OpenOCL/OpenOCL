classdef Function < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = public)
    functionHandle
    result
    inputs
    nOutputs
    obj
  end
  
  methods
    
    function self = Function(obj,functionHandle,inputs,nOutputs)
      self.obj = obj;
      self.functionHandle    = functionHandle;
      self.inputs = inputs;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
      
      ins = cell(1,length(self.inputs));
      for k=1:length(ins)
        ins{k} = Variable.createLike(varargin{k});
      end
      
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(self.obj,ins{:});
      
    end
    
  end
  
end

