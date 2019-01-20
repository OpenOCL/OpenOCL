classdef RaceCarSystem < OclSystem
  methods (Static)
    function setupVariables(self)
      self.addState('x');   % position x[m]
      self.addState('vx');  % velocity vx[m/s]
      self.addState('y');   % position y[m]
      self.addState('vy');  % velocity vy[m/s]
      
      self.addState('Fx');  % Force x[N]
      self.addState('Fy');  % Force x[N]
      
      self.addControl('dFx');  % Force x[N]
      self.addControl('dFy');  % Force x[N]
      
      self.addParameter('m');           % mass [kg]
      self.addParameter('A');           % section area car [m^2]
      self.addParameter('cd');          % drag coefficient [mini cooper 2008
      self.addParameter('rho');         % airdensity [kg/m^3]
      self.addParameter('Vmax');        % max speed [m/s]
      self.addParameter('road_bound');  % lane road relative to the middle lane [m]
      self.addParameter('Fmax');        % maximal force on the car [N]
    end
    function setupEquations(self,state,algVars,controls,parameters)    
      m    = parameters.m;
      A    = parameters.A;
      cd   = parameters.cd;
      rho  = parameters.rho;
      
      vx = state.vx;
      vy = state.vy;
      Fx = state.Fx;
      Fy = state.Fy;
      
      dFx = controls.dFx;
      dFy = controls.dFy;

      self.setODE( 'x',vx); 
      self.setODE('vx',1/m*Fx - 0.5*rho*cd*A*vx^2);
      self.setODE( 'y',vy);
      self.setODE('vy',1/m*Fy - 0.5*rho*cd*A*vx^2);
      self.setODE('Fx',dFx);
      self.setODE('Fy',dFy);
    end
  end
end

