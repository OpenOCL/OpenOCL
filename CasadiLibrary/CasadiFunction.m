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
    
    mx
    
    outputStructs
  end
  
  methods
    
    function self = CasadiFunction(inputFunction, jit, mx)
      % CasadiFunction(function,jit)
      % CasadiFunction(userFunction,jit)
      
      if isa(inputFunction,'CasadiFunction')
        self = inputFunction;
        return;
      end
      
      self.fun = inputFunction;
      
      
      if nargin == 1
        jit = false;
        self.mx = false;
      elseif nargin == 2
        self.mx = false;
      else
        self.mx = mx;
      end
      
      nInputs = length(inputFunction.inputs);
      inputs = cell(1,nInputs);
      for k=1:nInputs
        varStruct = inputFunction.inputs{k};
        inputs{k} = CasadiVariable.create(varStruct, self.mx);
      end
      
      nOutputs = inputFunction.nOutputs;
      
      self.outputStructs = cell(1,nOutputs);
      outputs = cell(1,nOutputs);
      
      [outputs{:}] = inputFunction.functionHandle(inputFunction.obj,inputs{:});
      
      for k=1:nOutputs
        self.outputStructs{k} = outputs{k}.type;
      end
      
      for k=1:nInputs
        inputs{k} = inputs{k}.value;
      end

      for k=1:nOutputs
        outputs{k} = outputs{k}.value;
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
      
      ins = cell(1,length(self.fun.inputs));
      for k=1:length(ins)
        ins{k} = varargin{k}.value;
      end
          
      % evaluate casadi function
      varargout = cell(1,self.fun.nOutputs);
      [varargout{:}] = self.casadiFun(ins{:});
      
      % replace numerical outputs
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
      
      for k=1:length(varargout)
        if isa(varargout{k},'casadi.DM')
          varargout{k} = Variable.create(self.outputStructs{k},full(varargout{k}));
        else
          varargout{k} = CasadiVariable.createLikeSameType(self.outputStructs{k},varargout{k});
        end
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

