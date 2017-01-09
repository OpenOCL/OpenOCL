classdef CasadiFunction < Function
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    fun
    numericOutputIndizes
    numericOutputValues
    
    compiled
    name = 'test'
  end
  
  methods
    
    function self = CasadiFunction(inputFunction,jit)
      self = self@Function(inputFunction.functionHandle,inputFunction.inputSizes,inputFunction.nOutputs);
      
      if nargin ==1
        jit = false;
      end
      
      N = length(self.inputSizes);
      inputs = cell(1,N);
      for k=1:N
        inputs{k} = casadi.MX.sym('in',self.inputSizes{k});
      end
      outputs = cell(1,self.nOutputs);
      [outputs{:}] = self.functionHandle(inputs{:});
      
      % check for numieric/constant outputs
      self.numericOutputIndizes = logical(cellfun(@isnumeric,outputs));
      self.numericOutputValues = outputs(self.numericOutputIndizes);
      
      self.fun = casadi.Function('fun',inputs,outputs,struct('jit',jit));
      if jit
        delete jit_tmp.c
      end
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.fun(varargin{:});
      
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

