classdef NlpValues < OclTensor

  properties
    manualInterpolation
    isInterpolated
  end
  
  methods (Static)
    function tensor = create(rn,value) 
      vs = OclValueStorage.allocate(value,numel(rn));
      vs.set(rn,value);
      tensor = NlpValues(rn,vs);
    end
  end

  methods
    function self = NlpValues(type,val)
      self@OclTensor(type,val);
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
                    'deactivated! If you wish to hide this warning set the option '...
                    'options.nlp.auto_interpolation to false.']);
        return;
      end
      
      uSize = self.get('controls').size();
      for i=1:uSize(3)
        state = self.get('states').slice(:,:,i).value;
        self.get('integrator',true).get('states').slice(:,:,i).set(state);
      end
      self.isInterpolated = true;
    end
    
    function r = get(self,id,autoSet)
      if strcmp(id,'integrator') && (nargin==2 || autoSet==false)
        self.manualInterpolation = true;
      end
      r = get@OclTensor(self,id);
    end
  end
end