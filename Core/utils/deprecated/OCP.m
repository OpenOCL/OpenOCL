classdef OCP
  
  methods
    function self = OCP(~)
      
      oclDeprecation(['The class OCP is deprecated. Please use OclOCP instead. ', ...
                      'Look at the documentation or examples of the latest version. ', ...
                      'Also look at the release notes to see what else has changed.', ...
                      'These changes include: System->OclSystem, OCP(system)->OclOCP()', ...
                      'Solver.getNLP and Solver.getSolver->OclSolver(VanDerPolSystem,VanDerPolOCP,options).']);
      error('Deprecated');
    end
  end
  
end