% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Simulator < handle

  properties
    integrator
    icfun
    daefun
    
    x_struct
    z_struct
    u_struct
    p_struct

    current_state
    algebraic_guess
    parameters
  end

  methods

    function self = Simulator(varargin)
      ocl.utils.checkStartup()
      
      p = ocl.utils.ArgumentParser;
      p.addKeyword('vars', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('dae', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('ic', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      
      p.addParameter('userdata', [], @(in)true);
      
      r = p.parse(varargin{:});

      varsfh = r.vars;
      daefh = r.dae;
      icfh = r.ic;
      userdata = r.userdata;
      
      [x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(varsfh, userdata);
      
      daefun = @(x,z,u,p) ocl.model.dae( ...
        daefh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, userdata);
      
      icfun = @(x,p) ocl.model.ic( ...
        icfh, ...
        x_struct, ...
        p_struct, ...
        x, p, userdata);

      nx = length(x_struct);
      nz = length(z_struct);
      nu = length(u_struct);
      np = length(p_struct);

      self.integrator = ocl.casadi.CasadiIntegrator( ...
        nx, nz, nu, np, daefun);
      
      self.daefun = daefun;
      self.icfun = icfun;
      
      self.x_struct = x_struct;
      self.z_struct = z_struct;
      self.u_struct = u_struct;
      self.p_struct = p_struct;

      self.current_state = [];
      self.algebraic_guess = 0;
      self.parameters = [];
    end

    function states = getStates(self)
      states = ocl.Variable.create(self.x_struct,0);
    end
    
    function z = getAlgebraicStates(self)
      z = ocl.Variable.create(self.z_struct,0);
    end
    
    function controls = getControls(self)
      controls = ocl.Variable.create(self.u_struct,0);
    end

    function states = getParameters(self)
      states = ocl.Variable.create(self.p_struct,0);
    end

    function [x] = reset(self,varargin)

      p = ocl.utils.ArgumentParser;
      p.addRequired('x0', @(el) isa(el, 'ocl.Variable') || isnumeric(el) );
      p.addKeyword('parameters', [], @(el) isa(el, 'ocl.Variable') || isnumeric(el));

      args = p.parse(varargin{:});

      initialStates = args.x0;
      if isnumeric(args.x0)
        initialStates = self.getStates();
        initialStates.set(args.x0);
      end

      params = args.parameters;
      if isnumeric(args.parameters)
        params = self.getParameters();
        params.set(args.parameters);
      end

      nz = length(self.z_struct);

      z = zeros(nz,1);
      x0 = ocl.Variable.getValueAsColumn(initialStates);
      p = ocl.Variable.getValueAsColumn(params);

      if ~isempty(z)
        [x0,z] = self.getConsistentIntitialCondition(x0,z,p);
      end
      
      initialStates.set(x0);

      self.current_state = x0;
      self.algebraic_guess = z;
      self.parameters = p;
    end

    function [states_out,algebraics_out] = step(self, controls_in, dt)

      if isnumeric(controls_in)
        controls = self.getControls();
        controls.set(controls_in);
      else
        controls = controls_in;
      end

      ocl.utils.assert(~isempty(self.current_state), 'Call `initialize` before `step`.');

      x = self.current_state;
      z0 = self.algebraic_guess;
      p = self.parameters;

      u = ocl.Variable.getValueAsColumn(controls);

      [x,z] = self.integrator.evaluate(x,z0,u,dt,p);

      states_out = self.getStates();
      states_out.set(x);

      algebraics_out = self.getAlgebraicStates();
      algebraics_out.set(z);

      self.current_state = x;
      self.algebraic_guess = z;

    end

    function [xOut,zOut] = getConsistentIntitialCondition(self,x,z,p)

      xSymb  = casadi.SX.sym('x',size(x));
      zSymb  = casadi.SX.sym('z',size(z));

      ic = self.icfun(xSymb,p);
      [~,alg] = self.daefun(xSymb,zSymb,0,p);

      z = ones(size(z)) * rand;

      optVars = [xSymb;zSymb];
      x0      = [x;z];

      statesErr = (xSymb-x);
      cost = statesErr'*statesErr;

      nlp    = struct('x', optVars, 'f', cost, 'g', vertcat(ic,alg));
      solver = casadi.nlpsol('solver', 'ipopt', nlp);
      sol    = solver('x0', x0, 'lbx', -inf, 'ubx', inf,'lbg', 0, 'ubg', 0);

      sol = full(sol.x);
      nx = size(x,1);

      xOut = sol(1:nx);
      zOut = sol(nx+1:end);

    end

  end

end
