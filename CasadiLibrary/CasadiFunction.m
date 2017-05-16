classdef CasadiFunction < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    fun
    casadiFun
    numericOutputIndizes
    numericOutputValues
    
    compiled
    name = 'test'
  end
  
  methods
    
    function self = CasadiFunction(inputFunction,jit)
      % CasadiFunction(function,jit)
      % CasadiFunction(userFunction,jit)
      
      self.fun = inputFunction;
      
      if nargin ==1
        jit = false;
      end
      
      nInputs = length(inputFunction.inputs);
      inputs = cell(1,nInputs);
      for k=1:nInputs
        varStruct = inputFunction.inputs{k};
        varValue = casadi.SX.sym(varStruct.id,varStruct.size);
        inputs{k} = Var(varStruct,varValue);
      end
      
      outputs = cell(1,inputFunction.nOutputs);
      [outputs{:}] = inputFunction.functionHandle(inputs{:});
      
      if isa(inputFunction,'UserFunction')
        for k=1:nInputs
          inputs{k} = inputs{k}.flat;
        end

        outputsCasadi = cell(1,inputFunction.nOutputs);
        for k=1:inputFunction.nOutputs
          outputsCasadi{k} = outputs{k}.flat;
        end
        outputs = outputsCasadi;
      end
      
      % check for numieric/constant outputs
      self.numericOutputIndizes = logical(cellfun(@isnumeric,outputs));
      self.numericOutputValues = outputs(self.numericOutputIndizes);
      
      self.casadiFun = casadi.Function('fun',inputs,outputs,struct('jit',jit));
%       self.casadiFun.expand();
      if jit
        delete jit_tmp.c
      end
    end
    
    function varargout = evaluate(self,varargin)
          
      % evaluate casadi function
      varargout = cell(1,self.fun.nOutputs);
      [varargout{:}] = self.casadiFun(varargin{:});
      
      % replace numerical outputs
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
    end
    
    function compile(self)
      global exportDir
      currentDir = pwd;
      cd(exportDir)
      opts = struct;
      opts.mex = true;
      cFilePath = fullfile(exportDir,[self.name '.c']);
      self.fun.generate([self.name '.c'],opts)
      cd(currentDir)
      
      % compile generated code as mex file
      mex(cFilePath,'-largeArrayDims')
      self.compiled = true;
    end
    
  end
end

