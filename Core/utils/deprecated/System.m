classdef System
  
  methods
    function self = System(varargin)
      
      oclDeprecation(['The class System is deprecated. Please use OclSystem instead. ', ...
                      'Look at the documentation or examples of the latest version. ', ...
                      'Also look at the release notes to see what else has changed.', ...
                      'These changes include: System->OclSystem, OCP(system)->OclOCP()', ...
                      'Solver.getNLP and Solver.getSolver->OclSolver(system,ocp,options).']);
      error('Deprecated');
    end
  end
  
end