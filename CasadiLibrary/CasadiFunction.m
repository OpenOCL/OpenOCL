% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef CasadiFunction < OclFunction
  properties (Access = public)
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
      
      nInputs = length(self.inputSizes);
      inputs = cell(1,nInputs);
      for k=1:nInputs
        s = self.inputSizes{k};
        assert(length(s)==2 || s(3)==1)
        if self.mx
          inputs{k} = casadi.MX.sym('v',s(1:2));
        else
          inputs{k} = casadi.SX.sym('v',s(1:2));
        end
      end
      
      outputs = cell(1,self.nOutputs);
      [outputs{:}] = fun.evaluate(inputs{:});
      
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

