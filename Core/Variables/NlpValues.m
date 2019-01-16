classdef NlpValues < Variable

  properties
    manualInterpolation
    isInterpolated
  end
  
  methods (Static)
    function var = create(type,value)
        [N,M,K] = type.size();
        v = OclValue(zeros(1,N,M,K));
        p = reshape(1:N*M*K,N,M,K);
        var = NlpValues(type,p,v);
        var.set(value);
    end
  end

  methods
    function self = NlpValues(type,positions,val)
      self@Variable(type,positions,val);
      self.manualInterpolation = false;
      self.isInterpolated = false;
    end
    
    function interpolateIntegrator(self)
      
      if self.isInterpolated
        return;
      end
      
      if self.manualInterpolation
        oclWarning(['You manually retreived or set the integrator variables. ', ...
                    'Automatic interpolation of the initial guess is therefore ', ...
                    'deactivated!']);
        return;
      end
      
      stateSize = self.get('controls').size();
      for i=1:stateSize(3)
        state = self.get('states').slice(:,:,i).value;
        self.get('integrator',true).slice(:,:,i).get('states').set(state);
      end
      self.isInterpolated = true;
    end
    
    function r = get(self,id,autoSet)
      if strcmp(id,'integrator') && (nargin==2 || autoSet==false)
        self.manualInterpolation = true;
      end
      r = get@Variable(self,id);
    end
  end
end