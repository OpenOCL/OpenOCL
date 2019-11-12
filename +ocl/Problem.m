classdef Problem < handle
  
  properties
    solver
    stage
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
      p.addParameter('print_level', 3, @isnumeric);
      
      p.addParameter('userdata', [], @(in)true);
      
      r = p.parse(varargin{:});
      
      stage = ocl.Stage(r.T, r.vars, r.dae, r.pathcosts, r.gridcosts, r.gridconstraints, ...
        r.terminalcost, ...
        'N', r.N, 'd', r.d, 'userdata', r.userdata);
      
      nlp_casadi_mx = r.nlp_casadi_mx;
      controls_regularization = r.controls_regularization;
      controls_regularization_value = r.controls_regularization_value;
      
      casadi_options = r.casadi_options;
      verbose = r.verbose;
      userdata = r.userdata;
      

      solver = ocl.casadi.CasadiSolver({stage}, {}, ...
                                       nlp_casadi_mx, controls_regularization, ...
                                       controls_regularization_value, casadi_options, ...
                                       verbose, userdata);
      
      % set instance variables
      self.stage = stage;
      self.solver = solver;
    end
    
    function [sol_r,times_r,info] = solve(self, ig)
      % [sol, times] = solve()
      % [sol, times] = solve(ig)

      s = self.solver;

      if nargin==1
        % ig InitialGuess
        ig = self.solver.getInitialGuessWithUserData();
        ig = ig{1};
      end

      [sol,times,solver_info] = s.solve({ig});

      sol_r = sol{1};
      times_r = times{1};
      
      if nargout >=3
        info = solver_info;
      end

      ocl.utils.warningNotice()
    end

    function r = timeMeasures(self)
      r = self.solver.timeMeasures;
    end

    function ig = ig(self)
      ig = self.getInitialGuess();
    end

    function ig = getInitialGuess(self)
      igList = self.solver.getInitialGuess();
      ig = igList{1};
    end
    
    function initialize(self, id, gridpoints, values, T)
      
      if nargin==5
        gridpoints = gridpoints / T;
      end

      self.stage.initialize(id, gridpoints, values);
    end

    function setParameter(self,id,varargin)
      self.stage.setParameterBounds(id, varargin{:});
    end

    function setBounds(self,id,varargin)
      % setBounds(id,value)
      % setBounds(id,lower,upper)
      
      % check if id is a state, control, algvar or parameter
      if ocl.utils.fieldnamesContain(self.stage.x_struct.getNames(), id)
        self.stage.setStateBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.stage.z_struct.getNames(), id)
        self.stage.setAlgvarBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.stage.u_struct.getNames(), id)
        self.stage.setControlBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.stage.p_struct.getNames(), id)
        self.stage.setParameterBounds(id, varargin{:});
      else
        ocl.utils.error(['You specified a bound for a variable that does not exist: ', id]);
      end
    end
    
    function setInitialState(self,id,value)
      % setInitialState(id,value)
      self.stage.setInitialStateBounds(id, value);
    end

    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.stage.setInitialStateBounds(id, varargin{:});
    end

    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.stage.setEndStateBounds(id, varargin{:});
    end
    
  end
  
end