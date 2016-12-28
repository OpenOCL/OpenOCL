classdef Function < handle
  %FUNCTION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = protected)
    functionHandle
    result
    inputSizes
    nOutputs
  end
  
  methods
    
    function self = Function(functionHandle,inputSizes,nOutputs)
      self.functionHandle    = functionHandle;
      self.inputSizes = inputSizes;
      self.nOutputs = nOutputs;
    end
    
    function varargout = evaluate(self,varargin)
%       for k=1:length(inputVars)
%         inputVars{k} = inputVars{k}.value;
%       end
      varargout = cell(1,self.nOutputs);
      [varargout{:}] = self.functionHandle(varargin{:});
    end
    
  end
  
end

