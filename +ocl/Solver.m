% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Solver < handle

  properties
    problem
  end

  methods

    function self = Solver(varargin)
      % ocl.Solver(T, 'vars', @varsfun, 'dae', @daefun,
      %            'pathcosts', @pathcostfun,
      %            'gridcosts', @gridcostfun,
      %            'gridconstraints', @gridconstraintsfun, casadi_options)
      % ocl.Solver(stages, transitions, casadi_options)
      
      ocl.utils.checkStartup()
      
      ocl.utils.deprecation('The use of ocl.Solver is dreprecated, please use ocl.Problem or ocl.MultiStageProblem instead.')

      if nargin >= 1 && isnumeric(varargin{1}) && ( isscalar(varargin{1}) || isempty(varargin{1}) )
        % ocl.Solver(T, 'vars', @varsfun, 'dae', @daefun,
        %            'lagrangecost', @lagrangefun,
        %            'pathcosts', @pathcostfun, options
        self.problem = ocl.Problem(varargin{:});
      else
        % ocl.Solver(stages, transitions, opt)
        self.problem = ocl.MultiStageProblem(varargin{:});
      end
    end

    function [sol,times] = solve(self, varargin)
      % [sol, times] = solve()
      % [sol, times] = solve(ig)
      [sol, times] = self.problem.solve(varargin{:});
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function ig = getInitialGuess(self)
      ig = self.problem.getInitialGuess();
    end
    
    function initialize(self, id, gridpoints, values, varargin)
      self.problem.initialize(id, gridpoints, values, varargin{:});
    end

    function setParameter(self,id,varargin)
      self.problem.setParameter(id, varargin{:});
    end

    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      self.problem.setBounds(id, varargin{:});
    end
    
    function setInitialState(self,id,value)
      % setInitialState(id,value)
      self.problem.setInitialState(id, value);
    end

    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.problem.setInitialBounds(id, varargin{:});
    end

    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.problem.setEndBounds(id, varargin{:});
    end

  end
end
