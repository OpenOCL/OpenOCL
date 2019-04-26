classdef OclPhase < handle

  properties
    T
    H_norm
    integrator
    
    pathcostfun
    arrivalcostfun
    pathconfun
    boundaryfun
    discretefun
    
    bounds
    bounds0
    boundsF
    parameterBounds
    
    nx
    nz
    nu
    np
    
    systemfun
  end
  
  properties (Access = private)
    pathcostfh
    arrivalcostfh
    pathconfh
    boundaryfh
    discretefh
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
      p.addOptional('discretecosts_opt', [], @oclIsFunHandleOrEmpty);
      
      p.addOptional('N_opt', [], @isnumeric);
      p.addOptional('integrator_opt', [], @isnumeric);
      
      p.addParameter('varsfun', empty_fh, @oclIsFunHandle);
      p.addParameter('daefun', empty_fh, @oclIsFunHandle);
      
      p.addParameter('pathcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('arrivalcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('pathconstraints', empty_fh, @oclIsFunHandle);
      p.addParameter('boundaryconditions', empty_fh, @oclIsFunHandle);
      p.addParameter('discretecosts', empty_fh, @oclIsFunHandle);
      
      p.addParameter('N', 30, @isnumeric);
      p.addParameter('integrator', OclCollocation(3), @(self)isa(self, 'OclCollocation'));
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
      
      discretecostsfh = p.Results.discretecosts_opt;
      if isempty(discretecostsfh)
        discretecostsfh = p.Results.discretecosts;
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
        if sum(self.H_norm) ~= 1
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
      self.discretefh = discretecostsfh;
      
      system = OclSystem(varsfh, daefh);
      system.setup()
      
      self.nx = system.nx();
      self.nz = system.nz();
      self.nu = system.nu();
      self.np = system.np();
      
      sx = system.statesStruct.size();
      sz = system.algVarsStruct.size();
      su = system.controlsStruct.size();
      sp = system.parametersStruct.size();
      
      self.systemfun = system.systemfun;
      
      self.integrator = integrator;
      
      fhPC = @(self,varargin) self.getPathCosts(varargin{:});
      self.pathcostfun = OclFunction(self, fhPC, {sx,sz,su,sp}, 1);
      
      fhAC = @(self,varargin) self.getArrivalCosts(varargin{:});
      self.arrivalcostfun = OclFunction(self, fhAC, {sx,sp}, 1);
      
      fhBC = @(self,varargin)self.getBoundaryConditions(varargin{:});
      self.boundaryfun = OclFunction(self, fhBC, {sx,sx,sp}, 3);
      
      fhPConst = @(self,varargin)self.getPathConstraints(varargin{:});
      self.pathconfun = OclFunction(self, fhPConst, {sx,sp}, 3);
      
%       fhDiscrete = @(self,varargin)self.getPathConstraints(varargin{:});
%       self.discretefun = OclFunction(self, fhDiscrete, {}, 1);

      self.bounds = system.bounds;
      self.parameterBounds = system.parameterBounds;

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
      pcHandler = OclCost(self.ocp);
      
      if self.options.controls_regularization
        pcHandler.add(self.options.controls_regularization_value*(u.'*u));
      end
      
      x = Variable.create(self.system.statesStruct,x);
      z = Variable.create(self.system.algVarsStruct,z);
      u = Variable.create(self.system.controlsStruct,u);
      p = Variable.create(self.system.parametersStruct,p);
      
      self.pathcosts(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end
    
    function r = getArrivalCosts(self,x,p)
      acHandler = OclCost(self.ocp);
      x = Variable.create(self.system.statesStruct,x);
      p = Variable.create(self.system.parametersStruct,p);
      
      self.arrivalcosts(acHandler,x,p);
      
      r = acHandler.value;
    end
    
    function [val,lb,ub] = getPathConstraints(self,x,p)
      pathConstraintHandler = OclConstraint(self.ocp);
      x = Variable.create(self.system.statesStruct,x);
      p = Variable.create(self.system.parametersStruct,p);
      
      self.pathconstraints(pathConstraintHandler,x,p);
      
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,x0,xF,p)
      bcHandler = OclConstraint(self.ocp);
      x0 = Variable.create(self.system.statesStruct,x0);
      xF = Variable.create(self.system.statesStruct,xF);
      p = Variable.create(self.system.parametersStruct,p);
      
      self.boundaryconditions(bcHandler,x0,xF,p);
      
      val = bcHandler.values;
      lb = bcHandler.lowerBounds;
      ub = bcHandler.upperBounds;
    end
    
    function r = getDiscreteCosts(self,v)
      dcHandler = OclCost(self.ocp);
      v = Variable.create(self.nlpVarsStruct,v);
      
      self.discretecosts(dcHandler,v);
      
      r = dcHandler.value;
    end
    
  end
  
end
