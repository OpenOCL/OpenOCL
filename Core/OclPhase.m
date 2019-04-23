classdef OclPhase < handle

  properties
    varsfun
    eqfun
    
    pathcostfun
    arrivalcostfun
    pathconfun
    boundaryfun
    discretefun
  end
  
  methods
    
    function self = OclPhase(varargin)
      
      defFhPC = @(varargin)[];
      defFhAC = @(varargin)[];
      defFhPCon = @(varargin)[];
      defFhBC = @(varargin)[];
      defFhDC = @(varargin)[];
      
      p = inputParser;
      p.addRequired('varsfun', @oclIsFunHandle);
      p.addRequired('eqfun', @oclIsFunHandle);
      
      p.addOptional('pathcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('arrivalcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pathconstraintsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('boundaryconditionsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('discretecostsOpt',[],@oclIsFunHandleOrEmpty);
      
      p.addParameter('pathcosts',defFhPC,@oclIsFunHandle);
      p.addParameter('arrivalcosts',defFhAC,@oclIsFunHandle);
      p.addParameter('pathconstraints',defFhPCon,@oclIsFunHandle);
      p.addParameter('boundaryconditions',defFhBC,@oclIsFunHandle);
      p.addParameter('discretecosts',defFhDC,@oclIsFunHandle);
      p.parse(varargin{:});
      
      
      pathcostsfun = p.Results.pathcostsOpt;
      if isempty(pathcostsfun)
        pathcostsfun = p.Results.pathcosts;
      end
      
      arrivalcostsfun = p.Results.arrivalcostsOpt;
      if isempty(arrivalcostsfun)
        arrivalcostsfun = p.Results.arrivalcosts;
      end
      
      pathconstraintsfun = p.Results.pathconstraintsOpt;
      if isempty(pathconstraintsfun)
        pathconstraintsfun = p.Results.pathconstraints;
      end
      
      boundaryconditionsfun = p.Results.boundaryconditionsOpt;
      if isempty(boundaryconditionsfun)
        boundaryconditionsfun = p.Results.boundaryconditions;
      end
      
      discretecostsfun = p.Results.discretecostsOpt;
      if isempty(discretecostsfun)
        discretecostsfun = p.Results.discretecosts;
      end
      
      self.varsfun = p.Results.varsfun;
      self.eqfun = p.Results.eqfun;
      self.pathcostfun = pathcostsfun;
      self.arrivalcostfun = arrivalcostsfun;
      self.pathconfun = pathconstraintsfun;
      self.boundaryfun = boundaryconditionsfun;
      self.discretefun = discretecostsfun;
      
    end
    
  end
  
end
