classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    pathcosts
    arrivalcosts
    pathconstraints
    boundaryconditions
    discretecosts
  end
  
  methods(Access = public)
    function self = OclOCP(varargin)
      % OclOCP(pathCostsFH,arrivalCostsFH,pathConstraintsFH,discreteCostsFH)
      
      defFhPC = @(varargin)[];
      defFhAC = @(varargin)[];
      defFhPCon = @(varargin)[];
      defFhBC = @(varargin)[];
      defFhDC = @(varargin)[];
      
      p = inputParser;
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
      
      self.pathcosts = pathcostsfun;
      self.arrivalcosts = arrivalcostsfun;
      self.pathconstraints = pathconstraintsfun;
      self.boundaryconditions = boundaryconditionsfun;
      self.discretecosts = discretecostsfun;
    end
  end
end

