classdef RaceCarOCP < OclOCP
  methods (Static)
    function arrivalCosts(self,state,parameters)
      self.addArrivalCost(parameters.T);
    end
    function pathConstraints(self,state,parameters)
      % speed constraint
      vx         = state.vx; 
      vy         = state.vy; 
      Vmax       = parameters.Vmax;
      road_bound = parameters.road_bound;
      self.addPathConstraint(vx^2+vy^2,'<=',Vmax^2);
      
      % force constraint
      Fx = state.Fx;
      Fy = state.Fy;
      Fmax       = parameters.Fmax;
      self.addPathConstraint(Fx^2+Fy^2,'<=',Fmax^2);
      
      % road bounds
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

