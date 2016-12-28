classdef ExampleOCP < OCP
  % An OCP is defined by inheriting from the OCP class.
  
  methods
    function self = ExampleOCP(model,endTime)
      % The constructor of OCP takes an instance of the model.
      % The end time of the horizon can be set to a real number, 
      % otherwise its 'free'.
      self = self@OCP(model);
      self.setEndTime(endTime);
      
    end
    function bounds(self)
      % Define bounds on the state, control, and algebraic variables.
      % Set bound either on all (':'), the first (1), or last ('end')
      % time interval along the horizon.
      
      % state bounds
      self.addBound('x',    ':',   -0.25, inf);   % -0.25 <= x <= inf
      self.addBound('u',    ':',   -1,    1);     % -1    <= u <= 1
      
      % intial state bounds
      self.addBound('x',     1,    0);            % x1 == 0
      self.addBound('y',     1,    1);            % y1 == 1
      
    end   
    function leastSquaresCost(self)
    end
    function lagrangeTerms(self,state,algState,controls,time,parameters)
      % Define lagrange (intermediate) cost terms.
      x  = state.get('x').value;
      y  = state.get('y').value;
      u  = controls.get('u').value;
      
      self.addLagrangeTerm( x^2 );
      self.addLagrangeTerm( y^2 );
      self.addLagrangeTerm( u^2 );
    end
    function mayerTerms(self,state,time,parameters)
      % Define terminal cost terms.
    end
    function pathConstraints(self,state,algState,controls,time,parameters)
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

