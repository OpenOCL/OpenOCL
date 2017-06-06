classdef ExampleOCP < OCP
  % An OCP is defined by inheriting from the OCP class.
  
  methods
    function self = ExampleOCP(system)
      % The constructor of OCP takes an instance of the system.
      % The end time of the horizon can be set to a real number, 
      % otherwise its 'free'.
      self = self@OCP(system);
    end
    function pathCosts(self,states,algVars,controls,time,parameters)
      % Define lagrange (intermediate) cost terms.
      x  = states.get('x');
      y  = states.get('y');
      u  = controls.get('u');
      
      self.addPathCost( x^2 );
      self.addPathCost( y^2 );
      self.addPathCost( u^2 );
    end
    function arrivalCosts(self,states,time,parameters)
      % Define terminal cost terms.
    end
    function pathConstraints(self,states,algVars,controls,time,parameters)
      % Define non-linear path constraints on variables.
    end    
    function boundaryConditions(self,states0,statesF,parameters)
      % Define non-linear terminal constraints.
    end
    
    function iterationCallback(self,variables)
      
      times = 0:10/30:10;
      hold off
      plot(times,variables.get('states').get('x').value,'-.')
      hold on
      plot(times,variables.get('states').get('y').value,'--k')
      stairs(times(1:end-1),variables.get('controls').get('u').value,'r')
      xlabel('time')
      legend({'x','y','u'})
      
      drawnow;
      waitforbuttonpress
      
    end
    
  end
  
end

