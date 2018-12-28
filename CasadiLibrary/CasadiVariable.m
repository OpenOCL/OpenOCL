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
    
    function self = CasadiVariable(structure,varargin)
      % CasadiVariable(structure)
      % CasadiVariable(structure,value)
      % CasadiVariable(structure,mx)
      % CasadiVariable(structure,mx,value)
      
      self = self@Variable(structure);
      
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

      if setvalue && isa(structure,'OclStructure')
        if self.mx
          value = casadi.MX.sym('v',prod(structure.size),1);
        else
          value = casadi.SX.sym('v',prod(structure.size),1);
        end
      elseif setvalue
        if self.mx
          value = casadi.MX.sym(structure.id,prod(structure.size),1);
        else
          value = casadi.SX.sym(structure.id,prod(structure.size),1);
        end
      end
      
      if isa(value,'Value')
        self.thisValue = value;
      else
        self.thisValue.set(value);
      end
      
    end
    
    
  end
  

  
end

