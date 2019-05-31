% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Simulator < handle

  properties
    integrator
    system
    options
  end

  methods (Static)
    function options = getOptions()
      options = struct;
    end
  end

  methods

    function self = Simulator(system,options)

      if nargin==1
        self.options = Simulator.getOptions();
      else
        self.options = options;
      end

      self.integrator = CasadiIntegrator(system);
      self.system = system;
    end

    function controlsVec = getControlsVec(self,N)
        controlsVecStruct  = OclStructure();
        controlsVecStruct.addRepeated({'u'},{self.system.controls},N);
        controlsVec = Variable.create(controlsVecStruct,0);
        controlsVec = controlsVec.u;
    end

    function states = getStates(self)
      states = Variable.create(self.system.states,0);
    end

    function states = getParameters(self)
      states = Variable.create(self.system.parameters,0);
    end

    function [statesVec,algVarsVec,controlsVec] = simulate(self,initialStates,times,varargin)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsVec,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsVec,parameters,callback)

      N = length(times)-1;
      callback = true;
      times = Variable.Matrix(times);
      if nargin == 4
        parameters = varargin{1};
        controlsVec = self.getControlsVec(N);
      elseif nargin == 5
        controlsVec = varargin{1};
        parameters = varargin{2};
      elseif nargin == 6
        controlsVec = varargin{1};
        parameters = varargin{2};
        callback = varargin{3};
      end

      statesVecStruct = OclStructure();
      statesVecStruct.addRepeated({'x'},{self.system.states},N+1);

      algVarsVecStruct = OclStructure();
      algVarsVecStruct.addRepeated({'z'},{self.system.algvars},N);

      statesVec = Variable.create(statesVecStruct,0);
      statesVec = statesVec.x;
      algVarsVec = Variable.create(algVarsVecStruct,0);
      algVarsVec = algVarsVec.z;

      nz = self.system.nz;
      nu = self.system.nu;

      z = zeros(nz,1);
      x0 = Variable.getValueAsColumn(initialStates);
      p = Variable.getValueAsColumn(parameters);
      times = Variable.getValueAsColumn(times);

      u0 = Variable.getValueAsColumn(controlsVec(:,:,1));

      [x,z] = self.getConsistentIntitialCondition(x0,z,u0,p);
      statesVec(:,:,1).set(x);

      % setup callback
      global testRun
      if callback && (isempty(testRun) || (testRun==false))
        self.system.callSimulationCallbackSetup();
      end

      for k=1:N-1

        t = times(k+1)-times(k);
        u = Variable.getValueAsColumn(controlsVec(:,:,k));

        if callback && (isempty(testRun) || (testRun==false))
          u = self.system.callSimulationCallback(x,z,u,times(k),times(k+1),p);
        end

        [x,z] = self.integrator.evaluate(x,z,u,t,p);

        statesVec(:,:,k+1).set(x);
        algVarsVec(:,:,k).set(z);
        controlsVec(:,:,k).set(u);
      end
      if callback && (isempty(testRun) || (testRun==false))
        u = self.system.callSimulationCallback(x,z,u,times(k),times(k+1),p);
      end
    end

    function [xOut,zOut] = getConsistentIntitialCondition(self,x,z,u,p)

      xSymb  = casadi.SX.sym('x',size(x));
      zSymb  = casadi.SX.sym('z',size(z));

      ic = self.system.icfun(xSymb,p);
      [~,alg] = self.system.daefun(xSymb,zSymb,u,p);

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
