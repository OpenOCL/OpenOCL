% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclSolver < handle

  properties (Access = private)
    bounds
    initialBounds
    endBounds
    igParameters

    solver
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

        phase = OclPhase(T, system.varsfh, system.daefh, ocp.pathcostsfh, ...
                         ocp.pointcostsfh, ocp.pointconstraintsfh, 'N', H_norm, 'd', d);

        self.cbfh = system.cbfh;

        phaseList{1} = phase;
        transitionList = {};
      elseif nargin >= 1 && ( isscalar(varargin{1}) || isempty(varargin{1}) )
        % OclSolver(T, 'vars', @varsfun, 'dae', @daefun,
        %           'lagrangecost', @lagrangefun,
        %           'pathcosts', @pathcostfun,
        p = inputParser;
        p.addRequired('T', @(el)isscalar(el) && isnumeric(el));

        p.addOptional('varsfunOpt', [], @oclIsFunHandleOrEmpty);
        p.addOptional('daefunOpt', [], @oclIsFunHandleOrEmpty);
        p.addOptional('pathcostsOpt', [], @oclIsFunHandleOrEmpty);
        p.addOptional('pointcostsOpt', [], @oclIsFunHandleOrEmpty);
        p.addOptional('pointconstraintsOpt', [], @oclIsFunHandleOrEmpty)

        p.addParameter('varsfun', emptyfh, @oclIsFunHandle);
        p.addParameter('daefun', emptyfh, @oclIsFunHandle);
        p.addParameter('pathcosts', emptyfh, @oclIsFunHandle);
        p.addParameter('pointcosts', emptyfh, @oclIsFunHandle);
        p.addParameter('pointconstraints', emptyfh, @oclIsFunHandle);

        p.addParameter('N', 30, @isnumeric);

        p.parse(varargin{:});
        transitionList = {};
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

      solver = CasadiSolver(phaseList, transitionList, options);

      % set instance variables
      self.phaseList = phaseList;
      self.solver = solver;
    end

    function r = jacobian_pattern(self, assignment)

      s = self.solver;
      ph_list = self.phaseList;

      v = s.nlpData.casadiNLP.x;
      g = s.nlpData.casadiNLP.g;
      jac_fun = casadi.Function('j', {v}, {jacobian(g, v)});

      values = cell(length(ph_list),1);
      for k=1:length(ph_list)
        values{k} = assignment{k}.value;
      end
      values = vertcat(values{:});
      r = jac_fun(values);
    end

    function [sol_ass,times_ass,objective_ass,constraints_ass] = solve(self, ig)

      s = self.solver;
      ph_list = self.phaseList;

      ig_list = cell(length(ph_list),1);
      for k=1:length(ph_list)
        ig_list{k} = ig{k}.value;
      end

      [sol,times,objective,constraints] = s.solve(ig_list);

      sol_list = cell(length(ph_list));
      times_list = cell(length(ph_list));
      obj_list = cell(length(ph_list));
      con_list = cell(length(ph_list));

      for k=1:length(ph_list)
        phase = ph_list{k};
        vars_structure = Simultaneous.vars(phase);
        times_structure = Simultaneous.times(phase);
        sol_list{k} = Variable.create(vars_structure, sol{k});
        times_list{k} = Variable.create(times_structure, times{k});
        obj_list{k} = objective{k};
        con_list{k} = constraints{k};
      end

      sol_ass = OclAssignment(sol_list);
      times_ass = OclAssignment(times_list);
      objective_ass = OclAssignment(obj_list);
      constraints_ass = OclAssignment(con_list);

      oclWarningNotice()
    end

    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function igAssignment = getInitialGuess(self)

      pl = self.phaseList;

      igList = cell(length(pl),1);
      for k=1:length(pl)
        phase = pl{k};
        varsStruct = Simultaneous.vars(phase);
        ig = Simultaneous.getInitialGuess(phase);
        igList{k} = Variable.create(varsStruct, ig);
      end

      igAssignment = OclAssignment(igList);

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
