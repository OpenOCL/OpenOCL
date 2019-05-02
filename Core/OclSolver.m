classdef OclSolver < handle
  
  properties (Access = private)
    bounds
    initialBounds
    endBounds
    igParameters
  end

  methods
    
    function self = OclSolver(varargin)
      % OclSolver(T, system, ocp, options, H_norm)
      % OclSolver(phase, options)
      % OclSolver(phaseList, options)
      % OclSolver(T, @varsfun, @daefun, @ocpfuns... , options)
      % OclSolver(phaseList, integratorList, options)
      preparationTic = tic;

      phaseList = {};

      if isnumeric(varargin{1}) && isa(varargin{2}, 'OclSystem')
        % OclSolver(T, system, ocp, options, H_norm)
        T = varargin{1};
        system = varargin{2};
        ocp = varargin{3};
        options = varargin{4};

        N = options.nlp.controlIntervals;
        d = options.nlp.collocationOrder;

        if nargin >= 5
          H_norm = varargin{5};
        else
          H_norm = repmat(1/N,1,N);
        end

        if length(T) == 1
          % T = final time
        elseif length(T) == N+1
          % T = N+1 timepoints at states
          H_norm = (T(2:N+1)-T(1:N))/ T(end);
          T = T(end);
        elseif length(T) == N
          % T = N timesteps
          H_norm = T/sum(T);
          T = sum(T);
        elseif isempty(T)
          % T = [] free end time
          T = [];
        else
          oclError('Dimension of T does not match the number of control intervals.')
        end
        
        integrator = OclCollocation(system.states, system.algvars, system.nu, system.np, @system.daefun, @ocp.lagrangecostfun, d);
        phase = OclPhase(T, H_norm, integrator, @ocp.pathcostsfun, @ocp.pathconfun);

        phaseList{1} = phase;
      end
      
      
      solver = CasadiSolver(phaseList, options);

      if strcmp(options.solverInterface,'casadi')
        preparationTime = toc(preparationTic);
        solver = CasadiNLPSolver(nlp,options);
        solver.timeMeasures.preparation = preparationTime;
      else
        error('Solver interface not implemented.')
      end 
    end
    
    function solve(self,ig)
      self.solver.solve(ig);
    end
    
    function setParameter(self,id,varargin)
      self.initialBounds = OclBound(id, varargin{:});
      self.igParameters.(id) = mean([varargin{:}]);
    end
    
    function setBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds = OclBounds(id, varargin{:});
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.initialBounds = OclBounds(id, varargin{:});
    end
    
    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.endBounds = OclBounds(id, varargin{:});
    end   
    
  end
end
