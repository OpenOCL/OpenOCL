classdef Solver < handle

  properties
    acados_ocp
  end


  methods
    function self = Solver(varargin)

      zerofh = @(varargin) 0;
      emptyfh = @(varargin) [];
      p = ocl.utils.ArgumentParser;

      p.addRequired('T', @(el)isnumeric(el) || isempty(el) );
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);

      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);

      r = p.parse(varargin{:});

      T = r.T;
      N = r.N;
      varsfh = r.vars;
      daefh = r.dae;
      gridcostsfh = r.gridcosts;
      gridconstraints = r.gridconstraints;

      ocp = ocl.acados.initialize( ...
                T, N, ...
                varsfh, daefh, gridcostsfh, pathcostsfh, gridconstraintsfh, ...
                x0, x_lb, x_ub, u_lb, u_ub);

      self.acados_ocp = ocp;

    end


    function solve(self)

      ocp = self.acados_ocp
      ocl.acados.solve(ocp);

    end

    function setInitialState(self, id, value)

      

    end

  end

end
