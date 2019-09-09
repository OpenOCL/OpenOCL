% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef CasadiVariable < ocl.Variable
  
  properties
    mx
  end
  
  methods (Static)
  
  
    function var = createFromValue(type,value)
      oclValue = ocl.types.Value(value);
      [N,M] = size(type);
      p = reshape(1:N*M,N,M);
      var = ocl.casadi.CasadiVariable(type,p,isa(value,'casadi.MX'),oclValue);
    end
    
    function var = create(type,mx)
      
      id = class(type);
      
      [N,M] = size(type);
      if N*M==0
        vv = [];
      elseif mx == true
        vv = casadi.MX.sym(id,N,M);
      else
        vv = casadi.SX.sym(id,N,M);
      end
      val = ocl.types.Value(vv);
      p = reshape(1:N*M,N,M);
      var = ocl.casadi.CasadiVariable(type,p,mx,val);
    end
    
    function obj = Matrix(size,mx)
      if nargin==1
        mx = false;
      end
      obj = ocl.casadi.CasadiVariable.create(ocl.types.Matrix(size),mx);
    end
  end
  
  methods
    
    function self = CasadiVariable(type,positions,mx,val)
      % CasadiVariable(type,positions,mx,val)
      narginchk(4,4);      
      self = self@ocl.Variable(type,positions,val);
      self.mx = mx;      
    end
    
    function disp(self)
      disp(self.str(self.value.str()));
    end
  end
end
