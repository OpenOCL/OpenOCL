classdef CasadiMapFunction < handle
  
  properties
    map_fcn
  end
  
  methods

    function self = CasadiMapFunction(casadi_fcn, N)
      self.map_fcn = casadi_fcn.casadiFun.map(N,'openmp');
    end
    
    function varargout = evaluate(self,varargin)
      varargout = cell(nargout,1);
      [varargout{:}] = self.map_fcn(varargin{:});
    end
  end
end