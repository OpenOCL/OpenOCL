classdef OclPhase < handle

  properties
    T
    H_norm
    d
    
    varsfun
    daefun
    
    pathcostfun
    arrivalcostfun
    pathconfun
    boundaryfun
    discretefun
    
    nx
    nz
    nu
    np
    
    systemfun
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
      p.addOptional('d_opt', [], @isnumeric);
      
      p.addParameter('varsfun', empty_fh, @oclIsFunHandle);
      p.addParameter('daefun', empty_fh, @oclIsFunHandle);
      
      p.addParameter('pathcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('arrivalcosts', empty_fh, @oclIsFunHandle);
      p.addParameter('pathconstraints', empty_fh, @oclIsFunHandle);
      p.addParameter('boundaryconditions', empty_fh, @oclIsFunHandle);
      p.addParameter('discretecosts', empty_fh, @oclIsFunHandle);
      
      p.addParameter('N', 30, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      p.parse(varargin{:});
      
      
      varsfun = p.Results.varsfun_opt;
      if isempty(varsfun)
        varsfun = p.Results.varsfun;
      end
      
      daefun = p.Results.daefun_opt;
      if isempty(daefun)
        daefun = p.Results.daefun;
      end
      
      pathcostsfun = p.Results.pathcosts_opt;
      if isempty(pathcostsfun)
        pathcostsfun = p.Results.pathcosts;
      end
      
      arrivalcostsfun = p.Results.arrivalcosts_opt;
      if isempty(arrivalcostsfun)
        arrivalcostsfun = p.Results.arrivalcosts;
      end
      
      pathconstraintsfun = p.Results.pathconstraints_opt;
      if isempty(pathconstraintsfun)
        pathconstraintsfun = p.Results.pathconstraints;
      end
      
      boundaryconditionsfun = p.Results.boundaryconditions_opt;
      if isempty(boundaryconditionsfun)
        boundaryconditionsfun = p.Results.boundaryconditions;
      end
      
      discretecostsfun = p.Results.discretecosts_opt;
      if isempty(discretecostsfun)
        discretecostsfun = p.Results.discretecosts;
      end
      
      N = p.Results.N_opt;
      if isempty(N)
        N = p.Results.N;
      end
      
      d = p.Results.d_opt;
      if isempty(d)
        d = p.Results.d;
      end
      
      T = p.Results.T;

      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      self.T = T;
      
      oclAssert( (isscalar(N) || isnumeric(N)) && isreal(N), ...
        ['Invalid value for parameter N.', oclDocMessage()] );
      if iscalar(N)
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
      
      oclAssert(isscalar(d) && isreal(d));
      self.d = d;
      
      self.varsfun = varsfun;
      self.daefun = daefun;
      
      self.pathcostfun = pathcostsfun;
      self.arrivalcostfun = arrivalcostsfun;
      self.pathconfun = pathconstraintsfun;
      self.boundaryfun = boundaryconditionsfun;
      self.discretefun = discretecostsfun;
      
      system = OclSystem(varsfun, daefun);
      system.setup()
      
      self.nx = system.nx();
      self.nz = system.nz();
      self.nu = system.nu();
      self.np = system.np();
      
      self.systemfun = system.systemFun;
      
    end
    
  end
  
end
