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
    stageList
  end

  methods

    function self = OclSolver(varargin)
      % OclSolver(T, system, ocp, options, H_norm)
      % OclSolver(T, 'vars', @varsfun, 'dae', @daefun,
      %           'pathcosts', @pathcostfun,
      %           'pointcosts', @pointcostfun,
      %           'pointconstraints', @pointconstraintsfun, casadi_options)
      % OclSolver(stages, transitions, casadi_options)

      if isnumeric(varargin{1}) && isa(varargin{2}, 'OclSystem')
        % OclSolver(T, system, ocp, options, H_norm)

        oclDeprecation(['This way of creating the solver ', ...
                        'is deprecated. It will be removed from version >5.01']);

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

        stage = OclStage(T, system.varsfh, system.daefh, ocp.pathcostsfh, ...
                         ocp.pointcostsfh, ocp.pointconstraintsfh, ...
                         system.callbacksetupfh, system.callbackfh, 'N', H_norm, 'd', d);

        stageList = {stage};
        transitionList = {};
        
        nlp_casadi_mx = options.nlp_casadi_mx;
        controls_regularization = options.controls_regularization;
        controls_regularization_value = options.controls_regularization_value;
        
        casadi_options = options.nlp.casadi;
        casadi_options.ipopt = options.nlp.ipopt;
        
      elseif nargin >= 1 && ( isscalar(varargin{1}) || isempty(varargin{1}) )
        % OclSolver(T, 'vars', @varsfun, 'dae', @daefun,
        %           'lagrangecost', @lagrangefun,
        %           'pathcosts', @pathcostfun, options
        
        zerofh = @(varargin) 0;
        emptyfh = @(varargin) [];
        p = ocl.utils.ArgumentParser;

        p.addRequired('T', @(el)isnumeric(el) || isempty(el) );
        p.addKeyword('vars', emptyfh, @oclIsFunHandle);
        p.addKeyword('dae', emptyfh, @oclIsFunHandle);
        p.addKeyword('pathcosts', zerofh, @oclIsFunHandle);
        p.addKeyword('pointcosts', zerofh, @oclIsFunHandle);
        p.addKeyword('pointconstraints', emptyfh, @oclIsFunHandle);
        
        p.addKeyword('callback', emptyfh, @oclIsFunHandle);
        p.addKeyword('callback_setup', emptyfh, @oclIsFunHandle);
        
        p.addParameter('nlp_casadi_mx', false, @islogical);
        p.addParameter('controls_regularization', true, @islogical);
        p.addParameter('controls_regularization_value', 1e-6, @isnumeric);
        
        p.addParameter('casadi_options', CasadiOptions(), @(el) isstruct(el));
        p.addParameter('N', 20, @isnumeric);
        p.addParameter('d', 3, @isnumeric);
        
        r = p.parse(varargin{:});
        
        stageList = {OclStage(r.T, r.vars, r.dae, r.pathcosts, r.pointcosts, r.pointconstraints, ...
                              r.callback_setup, r.callback, 'N', r.N, 'd', r.d)};
        transitionList = {};
        
        nlp_casadi_mx = r.nlp_casadi_mx;
        controls_regularization = r.controls_regularization;
        controls_regularization_value = r.controls_regularization_value;
        
        casadi_options = r.casadi_options;
        
      else
        % OclSolver(stages, transitions, opt)
        p = ocl.utils.ArgumentParser;

        p.addKeyword('stages', {}, @(el) iscell(el) || isa(el, 'OclStage'));
        p.addKeyword('transitions', {}, @(el) iscell(el) || ishandle(el) );
        
        p.addParameter('nlp_casadi_mx', false, @islogical);
        p.addParameter('controls_regularization', true, @islogical);
        p.addParameter('controls_regularization_value', 1e-6, @isnumeric);
        
        p.addParameter('casadi_options', CasadiOptions(), @(el) isstruct(el));
        
        r = p.parse(varargin{:});
        
        stageList = r.stages;
        transitionList = r.transitions;
        
        nlp_casadi_mx = r.nlp_casadi_mx;
        controls_regularization = r.controls_regularization;
        controls_regularization_value = r.controls_regularization_value;
        
        casadi_options = r.casadi_options;
      end

      solver = CasadiSolver(stageList, transitionList, ...
            nlp_casadi_mx, controls_regularization, controls_regularization_value, casadi_options);

      % set instance variables
      self.stageList = stageList;
      self.solver = solver;
    end

    function r = jacobian_pattern(self, assignment)

      s = self.solver;
      st_list = self.stageList;

      v = s.nlpData.casadiNLP.x;
      g = s.nlpData.casadiNLP.g;
      jac_fun = casadi.Function('j', {v}, {jacobian(g, v)});

      values = cell(length(st_list),1);
      for k=1:length(st_list)
        values{k} = assignment{k}.value;
      end
      values = vertcat(values{:});
      r = jac_fun(values);
    end

    function [sol_ass,times_ass,objective_ass,constraints_ass] = solve(self, ig)

      s = self.solver;
      st_list = self.stageList;
      
      if isa(ig, 'OclAssignment')
        ig_list = cell(length(st_list),1);
        for k=1:length(st_list)
          ig_list{k} = ig{k}.value;
        end
      else
        % ig InitialGuess
        ig_list = cell(length(st_list),1);
        for k=1:length(st_list)
          ig_stage = Simultaneous.getInitialGuessWithUserData(st_list{k}, ig{k});
          ig_list{k} = ig_stage.value;
        end
      end

      [sol,times,objective,constraints] = s.solve(ig_list);

      sol_list = cell(length(st_list));
      times_list = cell(length(st_list));
      obj_list = cell(length(st_list));
      con_list = cell(length(st_list));

      for k=1:length(st_list)
        stage = st_list{k};
        vars_structure = Simultaneous.vars(stage);
        times_structure = Simultaneous.times(stage);
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
    
    function ig_list = initialGuess(self)
      ig_list = cell(length(self.stageList), 1);
      for k=1:length(ig_list)
        ig_list{k} = ocl.InitialGuess(self.stageList{k}.states);
      end
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function igAssignment = getInitialGuess(self)

      pl = self.stageList;

      igList = cell(length(pl),1);
      for k=1:length(pl)
        stage = pl{k};
        varsStruct = Simultaneous.vars(stage);
        ig = Simultaneous.getInitialGuess(stage);
        igList{k} = Variable.create(varsStruct, ig);
      end

      igAssignment = OclAssignment(igList);
    end

    function solutionCallback(self,times,solution)
      
      for st_idx=1:length(self.stageList)
        sN = size(solution{st_idx}.states);
        N = sN(3);

        t = times{st_idx}.states;

        self.stageList{st_idx}.callbacksetupfun()

        for k=1:N-1
          x = solution{st_idx}.states(:,:,k+1);
          z = solution{st_idx}.integrator(:,:,k).algvars;
          u = solution{st_idx}.controls(:,:,k);
          p = solution{st_idx}.parameters(:,:,k);
          self.stageList{st_idx}.callbackfh(x,z,u,t(:,:,k),t(:,:,k+1),p);
        end
      end
      

    end

    function setParameter(self,id,varargin)
      if length(self.stageList) == 1
        self.stageList{1}.setParameterBounds(id, varargin{:});
      else
        oclError('For multi-stage problems, set the bounds to the stages directlly.')
      end
    end

    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      if length(self.stageList) == 1

        % check if id is a state, control, algvar or parameter
        if oclFieldnamesContain(self.stageList{1}.states.getNames(), id)
          self.stageList{1}.setStateBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.algvars.getNames(), id)
          self.stageList{1}.setAlgvarBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.controls.getNames(), id)
          self.stageList{1}.setControlBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.parameters.getNames(), id)
          self.stageList{1}.setParameterBounds(id, varargin{:});
        end

      else
        oclError('For multi-stage problems, set the bounds to the stages directly.')
      end
    end

    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      if length(self.stageList) == 1
        self.stageList{1}.setInitialStateBounds(id, varargin{:});
      else
        oclError('For multi-stage problems, set the bounds to the stages directly.')
      end
    end

    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      if length(self.stageList) == 1
        self.stageList{1}.setEndStateBounds(id, varargin{:});
      else
        oclError('For multi-stage problems, set the bounds to the stages directlly.')
      end
    end

  end
end
