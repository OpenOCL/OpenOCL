classdef Solver < handle

  properties
    acados_ocp

    state_bounds
    
    x_struct
    z_struct
    u_struct
    p_struct
    
    x_bounds
    u_bounds
    x0_bounds
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

      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);

      r = p.parse(varargin{:});

      T = r.T;
      N = r.N;
      varsfh = r.vars;
      daefh = r.dae;
      gridcostsfh = r.gridcosts;
      gridconstraintsfh = r.gridconstraints;
      
      [x_struct, z_struct, u_struct, p_struct, ...
        x_bounds, ~, u_bounds, ~, ...
        x_order] = ocl.model.vars(varsfh);

      nx = length(x_struct);
      nz = length(z_struct);
      nu = length(u_struct);
      np = length(p_struct);

      oclAssert(nz==0, 'No algebraic variable are currently support in the acados interface.');
      oclAssert(np==0, 'No parameters are currently support in the acados interface.');

      daefun = @(x,z,u,p) ocl.model.dae( ...
        daefh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, ...
        x, z, u, p);

      gridcostfun = @(k,K,x,p) ocl.model.gridcosts( ...
        gridcostsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p);

      pathcostfun = @(x,z,u,p) ocl.model.pathcosts( ...
        pathcostsfh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x, z, u, p);

      gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints( ...
        gridconstraintsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p);
      
      oclAssert(x0_lb == x0_ub, 'Need to set a fixed initial state x0 in the acados interface.');

      ocp = ocl.acados.initialize( ...
                nx, nu, ...
                T, N, ...
                daefun, gridcostfun, pathcostfun, gridconstraintfun);

      self.acados_ocp = ocp;
      self.x_struct = x_struct;
      self.z_struct = z_struct;
      self.u_struct = u_struct;
      self.p_struct = p_struct;
      
      self.x_bounds = x_bounds;
      self.u_bounds = u_bounds;
      self.x0_bounds = ocl.Bounds();
    end


    function solve(self)
      ocp = self.acados_ocp;
      ocl.acados.solve(ocp);
    end
    
    function setStateBounds(self, id, varargin)
      % bounds
      self.x_bounds.set(id, varargin{:})
      
      [x_lb, x_ub] = ocl.model.bounds(self.x_struct, self.x_bounds);
      [lbx, ubx, Jbx] = ocl.acados.bounds(x_lb, x_ub);
      
      self.acados_ocp.set('constr_Jbx', Jbx);
      self.acados_ocp.set('constr_lbx', lbx);
      self.acados_ocp.set('constr_ubx', ubx);
    end
    
    function setControlBounds(self, id, varargin)
      % bounds
      self.u_bounds.set(id, varargin{:})
      
      [u_lb, u_ub] = ocl.model.bounds(self.u_struct, self.u_bounds);
      [lbu, ubu, Jbu] = ocl.acados.bounds(u_lb, u_ub);
      
      self.acados_ocp.set('constr_Jbx', Jbu);
      self.acados_ocp.set('constr_lbx', lbu);
      self.acados_ocp.set('constr_ubx', ubu);
    end
    
    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      
      % check if id is a state, control, algvar or parameter
      if oclFieldnamesContain(self.x_struct.getNames(), id)
        self.setStateBounds(id, varargin{:});
      elseif oclFieldnamesContain(self.u_struct.getNames(), id)
        self.setControlBounds(id, varargin{:});
      else
        oclWarning(['You specified a bound for a variable that does not exist: ', id]);
      end
    end

    function setInitialState(self, id, value) 
      
      self.x0_bounds.set(id, value);
      [x0_lb, x0_ub] = ocl.model.bounds(self.x_struct, self.x0_bounds);
      
      oclAssert(x0_lb == x0_ub, 'Initial state must be a fixed value (not a box constraint).');
      ocp_model.set('constr_x0', x0_lb);
    end

  end

end
