classdef Solver < handle

  properties
    acados_ocp

    state_bounds
  end


  methods
    function self = Solver(varargin)

      zerofh = @(varargin) 0;
      emptyfh = @(varargin) [];
      p = ocl.utils.ArgumentParser;

      p.addRequired('T', @(el) isnumeric(el) || isempty(el) );
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);

      p.addKeyword('x0', ocl.Bounds(), @(el) isa(el, 'ocl.Bounds'));
      p.addKeyword('bounds', ocl.Bounds(), @(el) isa(el, 'ocl.Bounds'));

      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);

      r = p.parse(varargin{:});

      T = r.T;
      N = r.N;
      varsfh = r.vars;
      daefh = r.dae;
      gridcostsfh = r.gridcosts;
      gridconstraintsfh = r.gridconstraints;
      bounds = r.bounds;
      x0 = r.x0;
      
      [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0);
      [x_lb, x_ub] = ocl.model.bounds(x_struct, x0);
      [u_lb, u_ub] = ocl.model.bounds(u_struct, x0);
      
      oclAssert(x0_lb == x0_ub, 'Need to set a fixed initial state x0 in the acados interface.');

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
