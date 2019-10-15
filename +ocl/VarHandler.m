classdef VarHandler < handle
  
  properties
    x_struct
    z_struct
    u_struct
    p_struct
    
    x_bounds
    z_bounds
    u_bounds
    p_bounds
    
    x_order
    
    userdata_p
  end
  
  methods
    
    function self = VarHandler(userdata)
      
      self.x_struct = ocl.types.Structure();
      self.z_struct = ocl.types.Structure();
      self.u_struct = ocl.types.Structure();
      self.p_struct = ocl.types.Structure();
            
      self.x_bounds = ocl.types.Bounds();
      self.z_bounds = ocl.types.Bounds();
      self.u_bounds = ocl.types.Bounds();
      self.p_bounds = ocl.types.Bounds();
      
      self.x_order = {};
      
      self.userdata_p = userdata;
    end
    
    function r = userdata(self)
      r = self.userdata_p;
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

      self.x_struct.add(id, p.Results.s);
      self.x_bounds.set(id, p.Results.lb, p.Results.ub);
      
      self.x_order{end+1} = id;
      
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

      self.z_struct.add(id, p.Results.s);
      self.z_bounds.set(id, p.Results.lb, p.Results.ub);
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

      self.u_struct.add(id,p.Results.s);
      self.u_bounds.set(id, p.Results.lb, p.Results.ub);
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

      self.p_struct.add(id,p.Results.s);
      self.p_bounds.set(id, p.Results.default);
    end
  end
end