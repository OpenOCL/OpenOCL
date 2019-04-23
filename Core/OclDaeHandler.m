classdef OclDaeHandler < handle
  
  properties
    ode
    dae
  end
  
  methods
  
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
    
    function ode = getOde(self, nx)
      
      ode = struct2cell(self.ode);
      ode = vertcat(ode{:});
      if length(ode) ~= nx
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