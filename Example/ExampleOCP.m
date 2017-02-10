classdef ExampleOCP < OCP
  % An OCP is defined by inheriting from the OCP class.
  
  methods
    function self = ExampleOCP(model)
      % The constructor of OCP takes an instance of the model.
      % The end time of the horizon can be set to a real number, 
      % otherwise its 'free'.
      self = self@OCP(model);
    end
    function pathCosts(self,state,algState,controls,time,parameters)
      % Define lagrange (intermediate) cost terms.
      x  = state.get('x').value;
      y  = state.get('y').value;
      u  = controls.get('u').value;
      
      self.addPathCost( x^2 );
      self.addPathCost( y^2 );
      self.addPathCost( u^2 );
    end
    function arrivalCosts(self,state,time,parameters)
      % Define terminal cost terms.
    end
    function pathConstraints(self,state,algVars,controls,time,parameters)
      % Define non-linear path constraints on variables.
    end    
    function boundaryConditions(self,state,time,parameters)
      % Define non-linear terminal constraints.
    end
    
    function iterationCallback(self,variables)
      
      times = 0:10/30:10;
      hold off
      plot(times,variables.get('state').get('x').value,'-.')
      hold on
      plot(times,variables.get('state').get('y').value,'--k')
      stairs(times(1:end-1),variables.get('controls').get('u').value,'r')
      xlabel('time')
      legend({'x','y','u'})
      
      drawnow;
      waitforbuttonpress
      
    end
    
  end
  
end

