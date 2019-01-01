classdef CasadiFunction < OclFunction
  properties (Access = private)
    casadiFun
    numericOutputIndizes
    numericOutputValues
    mx
  end
  
  methods
    
    function self = CasadiFunction(fun, jit, mx)
      % CasadiFunction(function,jit)
      % CasadiFunction(userFunction,jit)
      self = self@OclFunction(fun.obj,fun.functionHandle,fun.inputSizes,fun.nOutputs);
      
      if isa(fun,'CasadiFunction')
        self = fun;
        return
      end
      
      if nargin == 1
        jit = false;
        self.mx = false;
      elseif nargin == 2
        self.mx = false;
      else
        self.mx = mx;
      end
      
      inputs = cell(1,length(self.inputSizes));
      for k=1:nInputs
        inputs{k} = casadi.SX.sym('v',self.inputSizes);
      end
      
      outputs = cell(1,self.nOutputs);
      [outputs{:}] = fun.evaluate(self.obj,inputs{:});
      
      % check for numeric/constant outputs
      self.numericOutputIndizes = logical(cellfun(@isnumeric,outputs));
      self.numericOutputValues = outputs(self.numericOutputIndizes);
      
      self.casadiFun = casadi.Function('fun',inputs,outputs,struct('jit',jit));
    end
    
    function varargout = evaluate(self,varargin)
      % evaluate casadi function
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.casadiFun(varargin{:});
      
      % replace numerical outputs
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
      
      for k=1:length(varargout)
        if isa(varargout{k},'casadi.DM')
          varargout{k} = full(varargout{k});
        end
      end
    end   
  end
end

