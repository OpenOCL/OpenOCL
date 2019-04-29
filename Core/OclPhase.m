classdef OclPhase < handle

  properties
    T
    H_norm
    integrator
    
    pathcostfun
    arrivalcostfun
    pathconfun
    boundaryfun
    pathcostdfun
    
    bounds
    bounds0
    boundsF
    parameterBounds
    
    nx
    nz
    nu
    np
    
    daefun

    states
    algvars
    controls
    parameters
  end
  
  properties (Access = private)
    pathcostfh
    arrivalcostfh
    pathconfh
    boundaryfh
    pathcostDfh
  end
  
  methods
    
    function self = OclPhase(varargin)
      
      empty_fh = @(varargin)[];
      
      p = inputParser;
      p.addRequired('T', @isnumeric);
      p.addOptional('varsfun_opt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('daefun_opt', [], @oclIsFunHandleOrEmpty);
      
      p.addOptional('pathcosts_opt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('arrivalcosts_opt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('pathconstraints_opt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('boundaryconditions_opt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('pathcostsD_opt', [], @oclIsFunHandleOrEmpty);
      
      p.addOptional('N_opt', [], @isnumeric);
      p.addOptional('integrator_opt', [], @(self)isempty(self)||isa(self, 'OclCollocation'));
      
      p.addParameter('varsfun', empty_fh, @oclIsFunHandle);
      p.addParameter('daefun', empty_fh, @oclIsFunHandle);
      
      p.addParameter('pathcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('arrivalcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('pathconstraints', empty_fh, @oclIsFunHandle);
      p.addParameter('boundaryconditions', empty_fh, @oclIsFunHandle);
      p.addParameter('pathcostsD', empty_fh, @oclIsFunHandle);
      
      p.addParameter('N', 30, @isnumeric);
      p.addParameter('integrator', [], @(self)isempty(self)||isa(self, 'OclCollocation'));
      p.parse(varargin{:});
      
      varsfh = p.Results.varsfun_opt;
      if isempty(varsfh)
        varsfh = p.Results.varsfun;
      end
      
      daefh = p.Results.daefun_opt;
      if isempty(daefh)
        daefh = p.Results.daefun;
      end
      
      pathcostsfh = p.Results.pathcosts_opt;
      if isempty(pathcostsfh)
        pathcostsfh = p.Results.pathcosts;
      end
      
      arrivalcostsfh = p.Results.arrivalcosts_opt;
      if isempty(arrivalcostsfh)
        arrivalcostsfh = p.Results.arrivalcosts;
      end
      
      pathconstraintsfh = p.Results.pathconstraints_opt;
      if isempty(pathconstraintsfh)
        pathconstraintsfh = p.Results.pathconstraints;
      end
      
      boundaryconditionsfh = p.Results.boundaryconditions_opt;
      if isempty(boundaryconditionsfh)
        boundaryconditionsfh = p.Results.boundaryconditions;
      end
      
      pathcostDfh = p.Results.pathcostsD_opt;
      if isempty(pathcostDfh)
        pathcostDfh = p.Results.pathcostsD;
      end
      
      N = p.Results.N_opt;
      if isempty(N)
        N = p.Results.N;
      end
      
      integrator = p.Results.integrator_opt;
      if isempty(integrator)
        integrator = p.Results.integrator;
      end
      
      T = p.Results.T;

      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      self.T = T;
      
      oclAssert( (isscalar(N) || isnumeric(N)) && isreal(N), ...
        ['Invalid value for parameter N.', oclDocMessage()] );
      if isscalar(N)
        self.H_norm = repmat(1/N, 1, N);
      else
        self.H_norm = N;
        if abs(sum(self.H_norm)-1) > eps 
          self.H_norm = self.H_norm/sum(self.H_norm);
          oclWarning(['Timesteps given in pararmeter N are not normalized! ', ...
                      'N either be a scalar value or a normalized vector with the length ', ...
                      'of the number of control interval. Check the documentation of N. ', ...
                      'Make sure the timesteps sum up to 1, and contain the relative ', ...
                      'length of the timesteps. OpenOCL normalizes the timesteps and proceeds.']);
        end
      end
      
      self.pathcostfh = pathcostsfh;
      self.arrivalcostfh = arrivalcostsfh;
      self.pathconfh = pathconstraintsfh;
      self.boundaryfh = boundaryconditionsfh;
      self.pathcostDfh = pathcostDfh;
      
      system = OclSystem(varsfh, daefh);
      
      self.nx = system.nx();
      self.nz = system.nz();
      self.nu = system.nu();
      self.np = system.np();
      
      self.states = system.states();
      self.algvars = system.algvars();
      self.controls = system.controls();
      self.parameters = system.parameters();
      
      sx = self.states.size();
      sz = self.algvars.size();
      su = self.controls.size();
      sp = self.parameters.size();
      
      self.daefun = system.daefun;
      
      if isempty(integrator)
        integrator = OclCollocation(system.states(), system.algvars, self.nu, self.np, self.daefun, 3);
      end
      self.integrator = integrator;

      self.bounds = system.bounds;
      self.parameterBounds = system.parameterBounds;

    end

    function r = N(self)
      r = length(self.H_norm);
    end
    
    function setBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds = OclBounds(id, varargin{:});
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds0 = OclBounds(id, varargin{:});
    end
    
    function setEndBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.boundsF = OclBounds(id, varargin{:});
    end
    
    function r = getPathCosts(self,x,z,u,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);
      
      self.pathcostfh(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end
    
    function r = getArrivalCosts(self,x,p)
      acHandler = OclCost();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.arrivalcostfh(acHandler,x,p);
      
      r = acHandler.value;
    end
    
    function [val,lb,ub] = getPathConstraints(self,x,p)
      pathConstraintHandler = OclConstraint();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathconfh(pathConstraintHandler,x,p);
      
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,x0,xF,p)
      bcHandler = OclConstraint();
      x0 = Variable.create(self.states,x0);
      xF = Variable.create(self.states,xF);
      p = Variable.create(self.parameters,p);
      
      self.boundaryfh(bcHandler,x0,xF,p);
      
      val = bcHandler.values;
      lb = bcHandler.lowerBounds;
      ub = bcHandler.upperBounds;
    end
    
    function r = getPathCostsD(self,x,z,u,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);
      
      self.pathcostDfh(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end
    
  end
  
end
