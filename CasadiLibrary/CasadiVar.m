classdef CasadiVar < Var
  %CASADIVAR Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
  end
  
  methods
    function self = CasadiVar(treeVar)
      value = casadi.SX.sym(treeVar.id,treeVar.size);
      self = self@Var(treeVar,value);
    end
    
    function v = value(self,sliceIn,varIn)
      
      if nargin == 1
        v = self.thisValue;
      else
        varSize = varIn.size;
        if varSize(1) ~= 1 && varSize(2) ~= 1
          
          % stack matrizes
          v = cell(1,length(sliceIn));
          for k=1:length(sliceIn)
            val = reshape( self.thisValue(sliceIn{k}) , varSize );
            v{k} = val;
          end
          
        else
          % stack vectors
          v = casadi.SX.sym('test',max(varSize),length(sliceIn));
          for k=1:length(sliceIn)
            val = reshape( self.thisValue(sliceIn{k}) , varSize );
            v(:,k) = val;
          end
        end
      end
    end
  end
  
end

