classdef Problem < handle
  
  properties
    solver
    stageList
  end
  
  
  methods
    
    function self = Problem(varargin)
      
      p = ocl.utils.ArgumentParser;
      
      p.addRequired('T', @(el)isnumeric(el) || isempty(el) );
      p.addKeyword('vars', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('dae', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('pathcosts', ocl.utils.zerofh, @ocl.utils.isFunHandle);
      p.addKeyword('gridcosts', ocl.utils.zerofh, @ocl.utils.isFunHandle);
      p.addKeyword('gridconstraints', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('terminalcost', ocl.utils.zerofh, @ocl.utils.isFunHandle);
      
      p.addParameter('nlp_casadi_mx', false, @islogical);
      p.addParameter('controls_regularization', true, @islogical);
      p.addParameter('controls_regularization_value', 1e-6, @isnumeric);
      
      p.addParameter('casadi_options', ocl.casadi.CasadiOptions(), @(el) isstruct(el));
      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      p.addParameter('verbose', true, @islogical);
      
      r = p.parse(varargin{:});
      
      stageList = {ocl.Stage(r.T, r.vars, r.dae, r.pathcosts, r.gridcosts, r.gridconstraints, ...
        r.terminalcost, ...
        'N', r.N, 'd', r.d)};
      transitionList = {};
      
      nlp_casadi_mx = r.nlp_casadi_mx;
      controls_regularization = r.controls_regularization;
      controls_regularization_value = r.controls_regularization_value;
      
      casadi_options = r.casadi_options;
      verbose = r.verbose;
      

      solver = ocl.casadi.CasadiSolver(stageList, transitionList, ...
                                       nlp_casadi_mx, controls_regularization, ...
                                       controls_regularization_value, casadi_options, ...
                                       verbose);
      
      % set instance variables
      self.stageList = stageList;
      self.solver = solver;
    end
    
    function [sol_ass,times_ass,objective_ass,constraints_ass] = solve(self, ig)
      % [sol, times] = solve()
      % [sol, times] = solve(ig)

      s = self.solver;
      st_list = self.stageList;

      if nargin==1
        % ig InitialGuess
        ig = self.solver.getInitialGuessWithUserData();
      end
      
      ig_list = cell(length(st_list),1);
      for k=1:length(st_list)
        ig_list{k} = ig{k}.value;
      end

      [sol,times,objective,constraints] = s.solve(ig_list);

      sol_ass = ocl.Assignment(sol);
      times_ass = ocl.Assignment(times);
      objective_ass = ocl.Assignment(objective);
      constraints_ass = ocl.Assignment(constraints);

      ocl.utils.warningNotice()
    end

    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function igAssignment = getInitialGuess(self)
      igList = self.solver.getInitialGuess();
      igAssignment = ocl.Assignment(igList);
    end
    
    function initialize(self, id, gridpoints, values, T)
      
      if nargin==5
        gridpoints = gridpoints / T;
      end
      
      if length(self.stageList) == 1
        self.stageList{1}.initialize(id, gridpoints, values);
      else
        ocl.utils.error('For multi-stage problems, set the guess to the stages directly.')
      end
    end

    function setParameter(self,id,varargin)
      if length(self.stageList) == 1
        self.stageList{1}.setParameterBounds(id, varargin{:});
      else
        ocl.utils.error('For multi-stage problems, set the bounds to the stages directly.')
      end
    end

    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      if length(self.stageList) == 1

        % check if id is a state, control, algvar or parameter
        if ocl.utils.fieldnamesContain(self.stageList{1}.x_struct.getNames(), id)
          self.stageList{1}.setStateBounds(id, varargin{:});
        elseif ocl.utils.fieldnamesContain(self.stageList{1}.z_struct.getNames(), id)
          self.stageList{1}.setAlgvarBounds(id, varargin{:});
        elseif ocl.utils.fieldnamesContain(self.stageList{1}.u_struct.getNames(), id)
          self.stageList{1}.setControlBounds(id, varargin{:});
        elseif ocl.utils.fieldnamesContain(self.stageList{1}.p_struct.getNames(), id)
          self.stageList{1}.setParameterBounds(id, varargin{:});
        else
          ocl.utils.error(['You specified a bound for a variable that does not exist: ', id]);
        end

      else
        ocl.utils.error('For multi-stage problems, set the bounds to the stages directly.')
      end
    end
    
    function setInitialState(self,id,value)
      % setInitialState(id,value)
      if length(self.stageList) == 1
        self.stageList{1}.setInitialStateBounds(id, value);
      else
        ocl.utils.error('For multi-stage problems, set the bounds to the stages directly.')
      end
    end

    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      if length(self.stageList) == 1
        self.stageList{1}.setInitialStateBounds(id, varargin{:});
      else
        ocl.utils.error('For multi-stage problems, set the bounds to the stages directly.')
      end
    end

    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      if length(self.stageList) == 1
        self.stageList{1}.setEndStateBounds(id, varargin{:});
      else
        ocl.utils.error('For multi-stage problems, set the bounds to the stages directlly.')
      end
    end
    
  end
  
end