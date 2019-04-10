classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    fh % function handles
  end
  
  methods(Access = public)
    function self = OclOCP(varargin)
      % OclOCP(pathCostsFH,arrivalCostsFH,pathConstraintsFH,discreteCostsFH)
      % OclOCP(__,'T',integrationEnd)
      
      defFhPC = @(varargin)self.pathCosts(varargin{:});
      defFhAC = @(varargin)self.arrivalCosts(varargin{:});
      defFhPCon = @(varargin)self.pathConstraints(varargin{:});
      defFhBC = @(varargin)self.boundaryConditions(varargin{:});
      defFhDC = @(varargin)self.discreteCosts(varargin{:});
      
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
      
      self.fh.pathCosts = pathcostsfun;
      self.fh.arrivalCosts = arrivalcostsfun;
      self.fh.pathConstraints = pathconstraintsfun;
      self.fh.boundaryConditions = boundaryconditionsfun;
      self.fh.discreteCosts = discretecostsfun;

      if nargin==1 && (isa(self.fh.pathCosts,'OclSystem') || isa(self.fh.pathCosts,'System'))
        oclDeprecation('Passing a system to the constructor of OclOCP is deprecated.');
      end
    end
  end
  
  methods (Static)
    %%% overridable methods
    function pathCosts(~,~,~,~,~,~,~)
      % pathCosts(self,states,algVars,controls,time,endTime,parameters)
    end
    function arrivalCosts(~,~,~,~)
      % arrivalCosts(self,states,endTime,parameters)
    end
    function pathConstraints(~,~,~,~)
      % pathConstraints(self,states,time,parameters)
    end
    function boundaryConditions(~,~,~,~)
      % boundaryConditions(self,initialStates,finalStates,parameters)
    end
    function discreteCosts(~,~)
      % discreteCost(self,vars)
    end
  end
end

