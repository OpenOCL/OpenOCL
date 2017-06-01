classdef Function < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = public)
    functionHandle
    result
    inputs
    outputs
  end
  
  methods
    
    function self = Function(functionHandle,inputs,outputs)
      self.functionHandle    = functionHandle;
      self.inputs = inputs;
      self.outputs = outputs;
    end
    
    function varargout = evaluate(self,varargin)
      
      ins = cell(1,length(self.inputs));
      for k=1:length(ins)
        ins{k} = Arithmetic.createFromValue(self.inputs{k},varargin{k});
      end
      
      varargout = cell(1,length(self.outputs));
      [varargout{:}] = self.functionHandle(ins{:});
      
      for k=1:length(varargout)
        varargout{k} = Arithmetic.create(ins{1},self.outputs{k},varargout{k});
      end
      
    end
    
  end
  
end

