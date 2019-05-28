classdef OclSolver < handle
  
  properties (Access = private)
    bounds
    initialBounds
    endBounds
    igParameters
    
    solver
    varsStruct
    phaseList
    
    cbfh
  end

  methods
    
    function self = OclSolver(varargin)
      % OclSolver(T, system, ocp, options, H_norm)
      % OclSolver(phaseList, options)
      % OclSolver(T, 'vars', @varsfun, 'dae', @daefun, 
      %           'lagrangecost', @lagrangefun, 
      %           'pathcosts', @pathcostfun, 
      %           'pathconstraints', @pathconstraintsfun, options)
      % OclSolver(phaseList, integratorList, options)
      phaseList = {};

      if isnumeric(varargin{1}) && isa(varargin{2}, 'OclSystem')
        % OclSolver(T, system, ocp, options, H_norm)
        
        oclDeprecation(['This way of creating the solver ', ...
                        'is deprecated. It will be removed from version 5.0.']);
        
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
    
        % for compatibility with older versions
        if length(T) == 1
          % T = final time
        elseif length(T) == N+1
          % T = N+1 timepoints at states
          OclDeprecation('Setting of multiple timepoints is deprecated, use the discretization parameter N instead.');
          H_norm = (T(2:N+1)-T(1:N))/ T(end);
          T = T(end);
        elseif length(T) == N
          % T = N timesteps
          OclDeprecation('Setting of multiple timesteps is deprecated, use the discretization parameter N instead.');
          H_norm = T/sum(T);
          T = sum(T);
        elseif isempty(T)
          % T = [] free end time
        else
          oclError('Dimension of T does not match the number of control intervals.')
        end
        
        phase = OclPhase(T, system.varsfh, system.daefh, ocp.lagrangecostsfh, ...
                         ocp.pathcostsfh, ocp.pathconfh, 'N', H_norm, 'd', d);
                       
        self.cbfh = system.cbfh;

        phaseList{1} = phase;
        transitionList = {};
      elseif nargin >= 1 && isscalar(varargin{1})
        % OclSolver(T, 'vars', @varsfun, 'dae', @daefun, 
        %           'lagrangecost', @lagrangefun, 
        %           'pathcosts', @pathcostfun, 
%         p = inputParser;
%         p.addRequired('T', @(el)isscalar(el) && isnumeric(el));
%         p.addOptional('varsfunOpt', [], @oclIsFunHandleOrEmpty);
%         p.addOptional('daefunOpt', [], @oclIsFunHandleOrEmpty);
%         
%         p.addParameter('varsfun', emptyfh, @oclIsFunHandle);
%         p.addParameter('daefun', emptyfh, @oclIsFunHandle);
%         
%         p.parse(varargin{:});
%         transitionList = {};
      else
        % OclSolver(phases, transitions, opt)
        p = inputParser;
        p.addOptional('phasesOpt', [], @(el) isempty(el) || iscell(el) || isa(el, 'OclPhase') );
        p.addOptional('transitionsOpt', [], @(el) isempty(el) || iscell(el) || ishandle(el) );
        p.addOptional('optionsOpt', [], @(el) isempty(el) || isstruct(el) || isa(el, 'OclOptions') );

        p.addParameter('phases', {}, @(el) iscell(el) || isa(el, 'OclPhase'));
        p.addParameter('transitions', {}, @(el) iscell(el) || ishandle(el) );
        p.addParameter('options', OclOptions(), @(el) isstruct(el) || isa(el, 'OclOptions'));
        p.parse(varargin{:});
        
        phaseList = p.Results.phasesOpt;
        if isempty(phaseList)
          phaseList = p.Results.phases;
        end
        
        transitionList = p.Results.transitionsOpt;
        if isempty(transitionList)
          transitionList = p.Results.transitions;
        end
        
        options = p.Results.optionsOpt;
        if isempty(options)
          options = p.Results.options;
        end
      end
      self.solver = CasadiSolver(phaseList, transitionList, options);
      self.varsStruct = Simultaneous.vars(phaseList);
      self.phaseList = phaseList;
    end
    
    function [outVars,times,objective,constraints] = solve(self,ig)
      [outVars,times,objective,constraints] = self.solver.solve(ig.value);
      outVars = Variable.create(self.varsStruct, outVars);
      
      timesStruct = Simultaneous.times(self.phaseList{1}.integrator.nt, length(self.phaseList{1}.H_norm));
      times = Variable.createNumeric(timesStruct, full(times));
    end
    
    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end
    
    function ig = ig(self)
      ig = self.getInitialGuess();
    end
    
    function ig = getInitialGuess(self)
      ig = Simultaneous.getInitialGuess(self.phaseList);
      ig = Variable.create(self.varsStruct, ig);
    end
    
    function solutionCallback(self,times,solution)
      sN = size(solution.states);
      N = sN(3);
      
      t = times.states;

      for k=1:N-1
        x = solution.states(:,:,k+1);
        z = solution.integrator(:,:,k).algvars;
        u =  solution.controls(:,:,k);
        p = solution.parameters(:,:,k);
        self.cbfh(x,z,u,t(:,:,k),t(:,:,k+1),p);
      end
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
