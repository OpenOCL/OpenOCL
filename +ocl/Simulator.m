% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Simulator < handle

  properties
    integrator
    system
    options

    current_state
    algebraic_guess
    parameters
  end

  methods

    function self = Simulator(system,options)
      ocl.utils.checkStartup()

      if nargin==1
        self.options = struct;
      else
        self.options = options;
      end

      self.integrator = ocl.casadi.CasadiIntegrator(system);
      self.system = system;

      self.current_state = [];
      self.algebraic_guess = 0;
      self.parameters = [];
    end

    function states = getStates(self)
      states = Variable.create(self.system.x_struct,0);
    end
    
    function z = getAlgebraicStates(self)
      z = Variable.create(self.system.z_struct,0);
    end
    
    function controls = getControls(self)
      controls = Variable.create(self.system.u_struct,0);
    end

    function states = getParameters(self)
      states = Variable.create(self.system.p_struct,0);
    end

    function [x] = reset(self,varargin)

      p = ocl.utils.ArgumentParser;
      p.addRequired('x0', @(el) isa(el, 'Variable') || isnumeric(el) );
      p.addKeyword('parameters', [], @(el) isa(el, 'Variable') || isnumeric(el));

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

      nz = self.system.nz;

      z = zeros(nz,1);
      x0 = Variable.getValueAsColumn(initialStates);
      p = Variable.getValueAsColumn(params);

      [x,z] = self.getConsistentIntitialCondition(x0,z,p);
      initialStates.set(x);

      self.current_state = x;
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

      oclAssert(~isempty(self.current_state), 'Call `initialize` before `step`.');

      x = self.current_state;
      z0 = self.algebraic_guess;
      p = self.parameters;

      u = Variable.getValueAsColumn(controls);

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

      ic = self.system.icfun(xSymb,p);
      [~,alg] = self.system.daefun(xSymb,zSymb,0,p);

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
