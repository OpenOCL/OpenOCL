classdef RaceCarSystem < System
  methods
    function setupVariables(self)
      % Define two scalar state variables
      self.addState('x' ,[1,1]); % position x[m]
      self.addState('vx',[1,1]); % velocity vx[m/s]
      self.addState('y' ,[1,1]); % position y[m]
      self.addState('vy',[1,1]); % velocity vy[m/s]
      
      % Define a scalar control variable
      self.addControl('Fx',[1,1]); % Force x[N]
      self.addControl('Fy',[1,1]); % Force x[N]
      
      self.addParameter('m'         ,[1 1]); % mass [kg]
      self.addParameter('A'         ,[1 1]); % section area car [m^2]
      self.addParameter('cd'        ,[1 1]); % drag coefficient [mini cooper 2008
      self.addParameter('rho'       ,[1 1]); % airdensity [kg/m^3]
      self.addParameter('Vmax'      ,[1 1]); % max speed [m/s]
      self.addParameter('road_bound',[1 1]); % lane road relative to the middle lane [m]
      self.addParameter('Fmax'      ,[1 1]); % maximal force on the car [N]
      
    end
    function setupEquation(self,state,algVars,controls,parameters)
      % Get access to the system parameters      
      m    = parameters.m;
      A    = parameters.A;
      cd   = parameters.cd;
      rho  = parameters.rho;
      
      % Get access to the system variables
      vx = state.vx;
      vy = state.vy;
      
      Fx = controls.Fx;
      Fy = controls.Fy;
           
      % Define differential equations
      self.setODE( 'x',vx); 
      self.setODE('vx',1/m*Fx - 0.5*rho*cd*A*vx^2);
      self.setODE( 'y',vy);
      self.setODE('vy',1/m*Fy - 0.5*rho*cd*A*vx^2);
    end
  end
end

