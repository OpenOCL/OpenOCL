classdef RaceCarOCP < OCP
  methods
    function self = RaceCarOCP(system)
      self = self@OCP(system);
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

