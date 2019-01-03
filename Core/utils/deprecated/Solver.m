classdef Solver
  
  methods
    function self = Solver(varargin)
      
      oclDeprecation(['The class Solver is deprecated. Please use OclSolver instead. ', ...
                      'Look at the documentation or examples of the latest version. ', ...
                      'Also look at the release notes to see what else has changed.', ...
                      'These changes include: System->OclSystem, OCP(system)->OclOCP()', ...
                      'Solver.getNLP and Solver.getSolver->OclSolver(system,ocp,options).']);
      error('Deprecated');
    end
  end
  
end