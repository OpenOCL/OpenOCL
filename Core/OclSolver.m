classdef OclSolver < handle
  
  properties (Access = private)
    bounds
    initialBounds
    endBounds
    igParameters
    
    solver
    varsStruct
    phaseList
  end

  methods
    
    function self = OclSolver(varargin)
      % OclSolver(T, system, ocp, options, H_norm)
      % OclSolver(phase, options)
      % OclSolver(phaseList, options)
      % OclSolver(T, @varsfun, @daefun, @ocpfuns... , options)
      % OclSolver(phaseList, integratorList, options)
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
        
        integrator = OclCollocation(system.states, system.algvars, system.controls, ...
            system.parameters, @system.daefun, ocp.lagrangecostsfh, d);
          
        phase = OclPhase(T, H_norm, integrator, ocp.pathcostsfh, ocp.pathconfh, ...
            system.states, system.algvars, system.controls, system.parameters);

        phaseList{1} = phase;
      end
      
      self.solver = CasadiSolver(phaseList, options);
      self.varsStruct = Simultaneous.vars(phaseList);
      self.phaseList = phaseList;
    end
    
    function [outVars,times,objective,constraints] = solve(self,ig)
      [outVars,times,objective,constraints] = self.solver.solve(ig.value);
      outVars = Variable.create(self.varsStruct, outVars);
      
      timesStruct = Simultaneous.times(self.phaseList{1}.integrator.nt, length(self.phaseList{1}.H_norm));
      times = Variable.createNumeric(timesStruct, full(times));
    end
    
    function ig = getInitialGuess(self)
      ig = Simultaneous.getInitialGuess(self.phaseList);
      ig = Variable.create(self.varsStruct, ig);
    end
    
    function setParameter(self,id,varargin)
      if length(self.phaseList) == 1
        self.phaseList{1}.setParameterBounds(id, varargin{:});
      else
        oclError('For multiphase problems, set the bounds to the phases directlly.')
      end
    end
    
    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      if length(self.phaseList) == 1
        
        % check if id is a state, control, algvar or parameter
        if oclFieldnamesContain(self.phaseList{1}.states.getNames(), id)
          self.phaseList{1}.setStateBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.phaseList{1}.algvars.getNames(), id)
          self.phaseList{1}.setAlgvarBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.phaseList{1}.controls.getNames(), id)
          self.phaseList{1}.setControlBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.phaseList{1}.parameters.getNames(), id)
          self.phaseList{1}.setParameterBounds(id, varargin{:});
        end
        
      else
        oclError('For multiphase problems, set the bounds to the phases directly.')
      end
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      if length(self.phaseList) == 1
        self.phaseList{1}.setInitialStateBounds(id, varargin{:});
      else
        oclError('For multiphase problems, set the bounds to the phases directly.')
      end
    end
    
    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      if length(self.phaseList) == 1
        self.phaseList{1}.setEndStateBounds(id, varargin{:});
      else
        oclError('For multiphase problems, set the bounds to the phases directlly.')
      end
    end   
    
  end
end
