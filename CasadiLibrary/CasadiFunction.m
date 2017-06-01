classdef CasadiFunction < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    inputs
    outputs
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
      self.inputs = cell(1,nInputs);
      for k=1:nInputs
        varStruct = inputFunction.inputs{k};
        self.inputs{k} = CasadiArithmetic(varStruct);
      end
      
      nOutputs = length(inputFunction.outputs);
      self.outputs = cell(1,nOutputs);
      [self.outputs{:}] = inputFunction.functionHandle(self.inputs{:});
      
      for k=1:nInputs
        self.inputs{k} = self.inputs{k}.value;
      end

      outputsCasadi = cell(1,nOutputs);
      for k=1:nOutputs
        outputsCasadi{k} = self.outputs{k}.value;
      end
      self.outputs = outputsCasadi;
      
      % check for numieric/constant outputs
      self.numericOutputIndizes = logical(cellfun(@isnumeric,self.outputs));
      self.numericOutputValues = self.outputs(self.numericOutputIndizes);
      
      self.casadiFun = casadi.Function('fun',self.inputs,self.outputs,struct('jit',jit));
%       self.casadiFun.expand();
      if jit
        delete jit_tmp.c
      end
    end
    
    function varargout = evaluate(self,varargin)
      
      ins = cell(1,length(self.inputs));
      for k=1:length(ins)
        ins{k} = varargin{k}.value;
      end
          
      % evaluate casadi function
      varargout = cell(1,length(self.fun.outputs));
      [varargout{:}] = self.casadiFun(ins{:});
      
      % replace numerical outputs
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
      
      for k=1:length(varargout)
        varargout{k} = CasadiArithmetic(self.outputs{k},varargout{k});
      end
      
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

