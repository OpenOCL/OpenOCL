classdef OclSysvarsHandler < handle
  
  properties
    statesStruct
    algVarsStruct
    parametersStruct
    controlsStruct
    
    bounds
    parameterBounds
    
    statesOrder
  end
  
  methods
    
    function self = OclSysvarsHandler()
      self.statesOrder = {};
      self.statesStruct = OclStructure();
      self.algVarsStruct = OclStructure();
      self.parametersStruct = OclStructure();
      self.controlsStruct = OclStructure();
      
      self.bounds = struct;
      self.parameterBounds = struct;
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

      self.statesStruct.add(id, p.Results.s);
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

      self.algVarsStruct.add(id, p.Results.s);
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

      self.controlsStruct.add(id,p.Results.s);
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

      self.parametersStruct.add(id,p.Results.s);
      self.parameterBounds.(id).lower = p.Results.default;
      self.parameterBounds.(id).upper = p.Results.default;
    end
  end
end