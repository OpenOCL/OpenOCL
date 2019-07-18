% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Solver < handle

  properties
    solver
    stageList
  end

  methods

    function self = Solver(varargin)
      % ocl.Solver(T, 'vars', @varsfun, 'dae', @daefun,
      %            'pathcosts', @pathcostfun,
      %            'gridcosts', @gridcostfun,
      %            'gridconstraints', @gridconstraintsfun, casadi_options)
      % ocl.Solver(stages, transitions, casadi_options)
      
      ocl.utils.checkStartup()

      if isnumeric(varargin{1}) && isa(varargin{2}, 'OclSystem')
        % ocl.Solver(T, system, ocp, options, H_norm)
        oclDeprecation(['This way of creating the solver ', ...
                        'is deprecated. It will be removed from version >5.01']);
        oclError('OclSystem is not supported anymore!');
        
      elseif nargin >= 1 && isnumeric(varargin{1}) && ( isscalar(varargin{1}) || isempty(varargin{1}) )
        % ocl.Solver(T, 'vars', @varsfun, 'dae', @daefun,
        %            'lagrangecost', @lagrangefun,
        %            'pathcosts', @pathcostfun, options
        
        zerofh = @(varargin) 0;
        emptyfh = @(varargin) [];
        p = ocl.utils.ArgumentParser;

        p.addRequired('T', @(el)isnumeric(el) || isempty(el) );
        p.addKeyword('vars', emptyfh, @oclIsFunHandle);
        p.addKeyword('dae', emptyfh, @oclIsFunHandle);
        p.addKeyword('pathcosts', zerofh, @oclIsFunHandle);
        p.addKeyword('gridcosts', zerofh, @oclIsFunHandle);
        p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);
        
        p.addParameter('nlp_casadi_mx', false, @islogical);
        p.addParameter('controls_regularization', true, @islogical);
        p.addParameter('controls_regularization_value', 1e-6, @isnumeric);
        
        p.addParameter('casadi_options', ocl.casadi.CasadiOptions(), @(el) isstruct(el));
        p.addParameter('N', 20, @isnumeric);
        p.addParameter('d', 3, @isnumeric);
        
        r = p.parse(varargin{:});
        
        stageList = {ocl.Stage(r.T, r.vars, r.dae, r.pathcosts, r.gridcosts, r.gridconstraints, ...
                               'N', r.N, 'd', r.d)};
        transitionList = {};
        
        nlp_casadi_mx = r.nlp_casadi_mx;
        controls_regularization = r.controls_regularization;
        controls_regularization_value = r.controls_regularization_value;
        
        casadi_options = r.casadi_options;
        
      else
        % ocl.Solver(stages, transitions, opt)
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

      solver = ocl.casadi.CasadiSolver(stageList, transitionList, ...
                                       nlp_casadi_mx, controls_regularization, ...
                                       controls_regularization_value, casadi_options);

      % set instance variables
      self.stageList = stageList;
      self.solver = solver;
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
          ig_stage = ocl.simultaneous.getInitialGuessWithUserData(st_list{k}, ig{k});
          ig_list{k} = ig_stage.value;
        end
      end

      [sol,times,objective,constraints] = s.solve(ig_list);

      sol_ass = OclAssignment(sol);
      times_ass = OclAssignment(times);
      objective_ass = OclAssignment(objective);
      constraints_ass = OclAssignment(constraints);

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
      igList = self.solver.getInitialGuess();
      igAssignment = OclAssignment(igList);
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
        if oclFieldnamesContain(self.stageList{1}.x_struct.getNames(), id)
          self.stageList{1}.setStateBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.z_struct.getNames(), id)
          self.stageList{1}.setAlgvarBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.u_struct.getNames(), id)
          self.stageList{1}.setControlBounds(id, varargin{:});
        elseif oclFieldnamesContain(self.stageList{1}.p_struct.getNames(), id)
          self.stageList{1}.setParameterBounds(id, varargin{:});
        else
          oclWarning(['You specified a bound for a variable that does not exist: ', id]);
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
