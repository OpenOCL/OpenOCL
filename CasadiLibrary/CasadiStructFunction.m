classdef CasadiStructFunction < CasadiFunction
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    fun
    numericOutputIndizes
    numericOutputValues
  end
  
  methods
    
    function self = CasadiStructFunction(inputFunction)
      self = self@CasadiFunction(inputFunction.functionHandle,inputFunction.inputSizes,inputFunction.nOutputs);
      
      N = length(self.inputSizes);
      inputs = cell(1,N);
      for k=1:N
        inputs{k} = casadi.SX.sym('in',self.inputSizes{k});
      end
      outputs = cell(1,self.nOutputs);
      [outputs{:}] = self.functionHandle(inputs{:});
      
      % check for numieric/constant outputs
      self.numericOutputIndizes = logical(cellfun(@isnumeric,outputs));
      self.numericOutputValues = outputs(self.numericOutputIndizes);
      
      self.fun = casadi.Function('fun',inputs,outputs);
      
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.fun(varargin{:});
      
      % replace numerical outputs
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
    end
    
  end
  
end

