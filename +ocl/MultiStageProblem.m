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

      r = p.parse(varargin{:});

      stageList = r.stages;
      transitionList = r.transitions;

      nlp_casadi_mx = r.nlp_casadi_mx;
      controls_regularization = r.controls_regularization;
      controls_regularization_value = r.controls_regularization_value;

      casadi_options = r.casadi_options;
      verbose = r.verbose;

      solver = ocl.casadi.CasadiSolver(stageList, transitionList, ...
                                       nlp_casadi_mx, controls_regularization, ...
                                       controls_regularization_value, casadi_options, ...
                                       verbose);

                                     
      % set instance variables
      self.stageList = stageList;
      self.solver = solver;
    end

    function [sol_ass,times_ass,objective_ass,constraints_ass] = solve(self, ig)
      % [sol, times] = solve()
      % [sol, times] = solve(ig)

      s = self.solver;
      st_list = self.stageList;

      if nargin==1
        % ig InitialGuess
        ig = self.solver.getInitialGuessWithUserData();
      end
      
      ig_list = cell(length(st_list),1);
      for k=1:length(st_list)
        ig_list{k} = ig{k}.value;
      end

      [sol,times,objective,constraints] = s.solve(ig_list);

      sol_ass = ocl.Assignment(sol);
      times_ass = ocl.Assignment(times);
      objective_ass = ocl.Assignment(objective);
      constraints_ass = ocl.Assignment(constraints);

      ocl.utils.warningNotice()
    end

    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function igAssignment = getInitialGuess(self)
      igList = self.solver.getInitialGuess();
      igAssignment = ocl.Assignment(igList);
    end
  end
end
