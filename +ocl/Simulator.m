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

      if nargin==1
        self.options = struct;
      else
        self.options = options;
      end

      self.integrator = CasadiIntegrator(system);
      self.system = system;

      self.current_state = [];
      self.algebraic_guess = 0;
      self.parameters = [];
    end

    function controlsVec = getControlsVec(self,N)
        controlsVecStruct  = OclStructure();
        controlsVecStruct.addRepeated({'u'},{self.system.u_struct},N);
        controlsVec = Variable.create(controlsVecStruct,0);
        controlsVec = controlsVec.u;
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
      p.addKeyword('callback', false, @islogical);

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

      useCallback = args.callback;

      nz = self.system.nz;

      z = zeros(nz,1);
      x0 = Variable.getValueAsColumn(initialStates);
      p = Variable.getValueAsColumn(params);

      [x,z] = self.getConsistentIntitialCondition(x0,z,p);
      initialStates.set(x);

      % setup callback
      if useCallback && ~oclIsTestRun
        self.system.callbacksetupfun();
      end

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

    function [statesVec,algVarsVec,controlsVec] = simulate(self,varargin)
      % [statesVec,algVarsVec,controlsVec] = 
      %     simulate(initialState, times, parameters=[], controlsVec=0, callback=false)

      p = ocl.utils.ArgumentParser;
      p.addRequired('x0', @(el) isa(el, 'Variable') || isnumeric(el) );
      p.addRequired('times', @isnumeric)

      p.addKeyword('controls', 0, @(el) isa(el, 'Variable') || isnumeric(el));
      p.addKeyword('parameters', [], @(el) isa(el, 'Variable') || isnumeric(el));
      p.addKeyword('callback', false, @islogical);

      args = p.parse(varargin{:});

      x0 = args.x0;
      if isnumeric(args.x0)
        x0 = self.getStates();
        x0.set(x0_in);
      end

      times = args.times;

      p = args.parameters;
      if isnumeric(args.parameters)
        p = self.getParameters();
        p.set(args.parameters);
      end

      N = length(times)-1; % number of control intervals

      controlsVec = args.controls;
      if isnumeric(args.controls)
        controlsVec = self.getControlsVec(N);
        controlsVec.set(args.controls);
      end

      x0 = self.reset(x0, p);

      useCallback = args.callback;

      statesVecStruct = OclStructure();
      statesVecStruct.addRepeated({'x'},{self.system.x_struct},N+1);

      algVarsVecStruct = OclStructure();
      algVarsVecStruct.addRepeated({'z'},{self.system.z_struct},N);

      statesVec = Variable.create(statesVecStruct,0);
      statesVec = statesVec.x;
      algVarsVec = Variable.create(algVarsVecStruct,0);
      algVarsVec = algVarsVec.z;
      
      statesVec(:,:,1).set(x0);

      for k=1:N-1

        x = self.current_state;
        z = self.algebraic_guess;
        p = self.parameters;

        t = times(k+1)-times(k);
        u = Variable.getValueAsColumn(controlsVec(:,:,k));

        if useCallback && ~ocl.utils.isTestRun
          u = self.system.callbackfun(x,z,u,times(k),times(k+1),p);
        end

        [x,z] = self.integrator.evaluate(x,z,u,t,p);

        self.current_state = x;
        self.algebraic_guess = z;

        statesVec(:,:,k+1).set(x);
        algVarsVec(:,:,k).set(z);
        controlsVec(:,:,k).set(u);

      end

      if useCallback && ~ocl.utils.isTestRun
        [~] = self.system.callbackfun(x,z,u,times(k),times(k+1),p);
      end

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
