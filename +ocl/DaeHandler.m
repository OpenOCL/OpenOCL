classdef DaeHandler < handle
  
  properties
    ode
    alg
    
    userdata_p
  end
  
  methods
    
    function self = DaeHandler(userdata)
      self.ode = struct;
      self.alg = [];
      self.userdata_p = userdata;
    end
    
    function r = userdata(self)
      r = self.userdata_p;
    end
  
     function setODE(self,id,eq)
      if isfield(self.ode, id)
        ocl.utils.exception(['Ode for var ', id, ' already defined']);
      end
      self.ode.(id) = ocl.Variable.getValueAsColumn(eq);
    end

    function setAlgEquation(self,eq)
      self.alg = [self.alg;ocl.Variable.getValueAsColumn(eq)];
    end
    
    function r = getOde(self, nx, statesOrder)

      r = cell(length(statesOrder),1);
      for k=1:length(statesOrder)
        id = statesOrder{k};
        if ~isfield(self.ode,id)
          ocl.utils.exception(['Ode for state ', id, ' not defined.']);
        end
        r{k} = self.ode.(id);
        self.ode = rmfield(self.ode, id);
      end
      r = vertcat(r{:});
      
      if length(r) ~= nx
        ocl.utils.exception(['Number of ode equations does not match ',...
                      'number of state variables.']);
      end
      
      if numel(fieldnames(self.ode)) > 0
        ocl.utils.exception('ODE for variables defined that do not exist.');
      end
    end
    
    function alg = getAlg(self, nz)
      alg = self.alg;
      if length(alg) ~= nz
        ocl.utils.exception(['Number of algebraic equations does not match ',...
                      'number of algebraic variables.']);
      end
    end
  end
end