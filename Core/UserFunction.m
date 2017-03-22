classdef UserFunction < Function
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = protected)
  end
  
  methods
    
    function self = UserFunction(functionHandle,inputs,nOutputs)
      self = self@Function(functionHandle,inputs,nOutputs);
    end
    
    function varargout = evaluate(self,varargin)
      
      for k=1:length(varargin)
        self.inputs{k}.set(varargin{k});
      end
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(self.inputs{:});
      
      for k=1:self.nOutputs
        varargout{k} = varargout{k}.flat;
      end
      
    end
    
  end
  
end

