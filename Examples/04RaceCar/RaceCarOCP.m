classdef RaceCarOCP < OclOCP
  methods (Static)
    function arrivalCosts(ch,state,parameters)
      ch.add(parameters.T);
    end
    function pathConstraints(ch,state,parameters)
      % speed constraint
      vx         = state.vx; 
      vy         = state.vy; 
      Vmax       = parameters.Vmax;
      road_bound = parameters.road_bound;
      ch.add(vx^2+vy^2,'<=',Vmax^2);
      
      % force constraint
      Fx = state.Fx;
      Fy = state.Fy;
      Fmax       = parameters.Fmax;
      ch.add(Fx^2+Fy^2,'<=',Fmax^2);
      
      % road bounds
      x  = state.x; 
      y  = state.y;
      
      y_center = sin(x);
      y_max = y_center + road_bound;
      y_min = y_center - road_bound;
      ch.add(y,'<=',y_max);
      ch.add(y,'>=',y_min);
    end
  end
end

