classdef RaceCarOCP < OCP
  % An OCP is defined by inheriting from the OCP class.

  methods
    function self = RaceCarOCP(system)
      % The constructor of OCP takes an instance of the system.
      % The end time of the horizon can be set to a real number, 
      % otherwise its 'free'.
      self = self@OCP(system);
    end
    function pathCosts(self,state,algState,controls,time,endTime,params)
      % Define lagrange (intermediate) cost terms.
      % x  = state.get( 'x').value; 
      % self.addPathCost( Fx^2 + Fy^2 );
      
    end
    function arrivalCosts(self,state,time,parameters)
      % Define terminal cost terms.
      self.addArrivalCost(time);
    end
    function pathConstraints(self,state,algVars,controls,time,parameters)
      % Define non-linear path constraints on variables.
      
      
      % constrain maximal speed
      vx         = state.vx; 
      vy         = state.vy; 
      Vmax       = parameters.Vmax;
      road_bound = parameters.road_bound;
      self.addPathConstraint(vx^2+vy^2,'<=',Vmax^2);
      
      % constrain maximal forces
      Fx = controls.Fx;
      Fy = controls.Fy;
      Fmax       = parameters.Fmax;
      self.addPathConstraint(Fx^2+Fy^2,'<=',Fmax^2);
      
      
      % constrain to road bounds
      x  = state.x; 
      y  = state.y;
      
      y_center = sin(x);
      y_max = y_center + road_bound;
      y_min = y_center - road_bound;
      
      self.addPathConstraint(y,'<=',y_max);
      self.addPathConstraint(y,'>=',y_min);
      
    end
    
  end
  
end

