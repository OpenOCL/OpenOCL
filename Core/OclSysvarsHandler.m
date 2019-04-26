classdef OclSysvarsHandler < handle
  
  properties (Access = private)
    states
    algvars
    parameters
    controls
    
    bounds
    parameterBounds
    
    statesOrder
  end
  
  methods
    
    function self = OclSysvarsHandler()
      self.statesOrder = {};
      self.states = OclStructure();
      self.algvars = OclStructure();
      self.controls = OclStructure();
      self.parameters = OclStructure();
            
      self.bounds = struct;
      self.parameterBounds = struct;
    end
    
    function s = getSysvars(self)
      s = struct;
      s.states = self.states;
      s.algvars = self.algvars;
      s.controls = self.controls;
      s.parameters = self.parameters;
      s.statesOrder = self.statesOrder;
      s.bounds = self.bounds;
      s.parameterBounds = self.parameterBounds;
    end
    
    function addState(self,id,varargin)
      % addState(id)
      % addState(id,s)
      % addState(id,s,lb=lb,lb=ub)

      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.states.add(id, p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
      
      self.statesOrder{end+1} = id;
      
    end
    function addAlgVar(self,id,varargin)
      % addAlgVar(id)
      % addAlgVar(id,s)
      % addAlgVar(id,s,lb=lb,ub=ub)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.algvars.add(id, p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
    end
    function addControl(self,id,varargin)
      % addControl(id)
      % addControl(id,s)
      % addControl(id,s,lb=lb,ub=ub)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.controls.add(id,p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
    end
    function addParameter(self,id,varargin)
      % addParameter(id)
      % addParameter(id,s)
      % addParameter(id,s,defaultValue)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('default', 0, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.parameters.add(id,p.Results.s);
      self.parameterBounds.(id).lower = p.Results.default;
      self.parameterBounds.(id).upper = p.Results.default;
    end
  end
end