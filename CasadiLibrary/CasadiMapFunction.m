% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef CasadiMapFunction < handle
  
  properties
    N
    map_fcn
    numericOutputIndizes
    numericOutputValues
  end
  
  methods

    function self = CasadiMapFunction(casadi_fcn, N)
      self.N = N;
      self.map_fcn = casadi_fcn.casadiFun.map(N,'openmp');
      self.numericOutputIndizes = casadi_fcn.numericOutputIndizes;
      
      for i=1:numel(casadi_fcn.numericOutputValues)
        % repmat output values
        self.numericOutputValues{i}  = repmat(casadi_fcn.numericOutputValues{i},1,N);
      end
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(nargout,1);
      [varargout{:}] = self.map_fcn(varargin{:});
      
      varargout(self.numericOutputIndizes) = self.numericOutputValues;
      
      for k=1:length(varargout)
        if isa(varargout{k},'casadi.DM')
          varargout{k} = full(varargout{k});
        end
      end

    end
  end
end