classdef OclDaeHandler < handle
  
  properties
    ode
    alg
    
    statesOrder
  end
  
  methods
    
    function self = OclDaeHandler(statesOrder)
      self.statesOrder = statesOrder;
    end
  
     function setODE(self,id,eq)
      if ~isfield(self.ode,id)
        oclException(['State ', id, ' does not exist.']);
      end
      if ~isempty(self.ode.(id))
        oclException(['Ode for var ', id, ' already defined']);
      end
      self.ode.(id) = Variable.getValueAsColumn(eq);
    end

    function setAlgEquation(self,eq)
      self.alg = [self.alg;Variable.getValueAsColumn(eq)];
    end
    
    function r = getOde(self, nx)
      
      r = cell(length(self.statesOrder),1);
      for k=1:length(self.statesOrder)
        id = self.statesOrder{k};
        r{k} = self.ode.(id);
      end
      r = vertcat(r{:});
      
      if length(r) ~= nx
        oclException(['Number of ode equations does not match ',...
                      'number of state variables.']);
      end
      
    end
    
    function alg = getAlg(self, nz)
      
      alg = self.alg;
      if length(alg) ~= nz
        oclException(['Number of algebraic equations does not match ',...
                      'number of algebraic variables.']);
      end
    end
    
    
  end


end