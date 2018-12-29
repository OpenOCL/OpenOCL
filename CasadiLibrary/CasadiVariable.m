classdef CasadiVariable < Variable
  
  properties
    mx
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      obj = CasadiVariable(OclMatrix(sizeIn));
    end
    
  end
  
  methods
    
    function self = CasadiVariable(type,varargin)
      % CasadiVariable(type)
      % CasadiVariable(type,value)
      % CasadiVariable(type,mx)
      % CasadiVariable(type,mx,value)
      
      self = self@Variable(type);
      
      setvalue = false;
      if nargin==1 || (nargin==2 && islogical(varargin{1}))
        setvalue = true;
        if nargin==1
          self.mx=false;
        else
          self.mx=varargin{1};
        end
      elseif nargin==3
        self.mx = varargin{1};
        value = varargin{2};
      else
        self.mx = false;
        value = varargin{1};
      end

      if setvalue && isa(type,'OclStructure')
        if self.mx
          value = casadi.MX.sym('v',prod(type.size),1);
        else
          value = casadi.SX.sym('v',prod(type.size),1);
        end
      elseif setvalue
        if self.mx
          value = casadi.MX.sym(type.id,prod(type.size),1);
        else
          value = casadi.SX.sym(type.id,prod(type.size),1);
        end
      end
      
      if isa(value,'Value')
        self.val = value;
      else
        self.val.set(value);
      end
    end
  end
end
