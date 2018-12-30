classdef CasadiVariable < Variable
  
  properties
    mx
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      val = Value(OclMatrix(sizeIn),1:prod(sizeIn),casadi.SX.sym('v',1,prod(sizeIn)));
      obj = CasadiVariable(false,val);
    end
    
  end
  
  methods
    
    function self = CasadiVariable(mx,val)
      % CasadiVariable(mx)
      % CasadiVariable(mx,val)
      % CasadiVariable(mx,var)
      narginchk(1,2);      
      self = self@Variable(val);
      self.mx = mx;
      
%       if isa(type,'OclTree')
%         names = fieldnames(type.children);
%         id = [names{:}];
%       else
%         id = class(type);
%       end
      
%             if nargin == 1 && mx
%         val = 
%       elseif nargin == 1
%         val = Value(OclMatrix(size(val)),1:prod(sizeIn),casadi.SX.sym(id,1,prod(type.size)));
%       end
      
    end
  end
end
