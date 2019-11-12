% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef MultiStageProblem < handle

  properties
    solver
    stageList
  end

  methods

    function self = MultiStageProblem(varargin)
      % ocl.Solver(stages, transitions, casadi_options)
      
      ocl.utils.checkStartup()

      % ocl.Solver(stages, transitions, opt)
      p = ocl.utils.ArgumentParser;

      p.addKeyword('stages', {}, @(el) iscell(el) || isa(el, 'ocl.Stage'));
      p.addKeyword('transitions', {}, @(el) iscell(el) || ishandle(el) );

      p.addParameter('nlp_casadi_mx', false, @islogical);
      p.addParameter('controls_regularization', true, @islogical);
      p.addParameter('controls_regularization_value', 1e-6, @isnumeric);

      p.addParameter('casadi_options', ocl.casadi.CasadiOptions(), @(el) isstruct(el));
      p.addParameter('verbose', true, @islogical);
      p.addParameter('userdata', [], @(in)true);
      p.addParameter('transition_type', 1, @isnumeric);

      r = p.parse(varargin{:});

      stageList = r.stages;
      transitionList = r.transitions;

      nlp_casadi_mx = r.nlp_casadi_mx;
      controls_regularization = r.controls_regularization;
      controls_regularization_value = r.controls_regularization_value;

      casadi_options = r.casadi_options;
      verbose = r.verbose;
      userdata = r.userdata;
      transition_type = r.transition_type;

      solver = ocl.casadi.CasadiSolver(stageList, transitionList, ...
                                       nlp_casadi_mx, controls_regularization, ...
                                       controls_regularization_value, casadi_options, ...
                                       verbose, userdata, transition_type);

                                     
      % set instance variables
      self.stageList = stageList;
      self.solver = solver;
    end

    function [sol,times,info] = solve(self, ig)
      % [sol, times] = solve()
      % [sol, times] = solve(ig)

      s = self.solver;

      if nargin==1
        % ig InitialGuess
        ig = self.solver.getInitialGuessWithUserData();
      end

      [sol,times,solver_info] = s.solve(ig);

      if nargout >=3
        info = solver_info;
      end

      ocl.utils.warningNotice()
    end

    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function igList = getInitialGuess(self)
      igList = self.solver.getInitialGuess();
    end
  end
end
