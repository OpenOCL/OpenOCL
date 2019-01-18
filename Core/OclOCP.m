classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    fh % function handles
    T
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
      p.addRequired('T',@(v)isnumeric(v)&&(numel(v)==1||isempty(v)));
      p.addOptional('pathCosts',defFhPC,@oclIsFunHandle);
      p.addOptional('arrivalCosts',defFhAC,@oclIsFunHandle);
      p.addOptional('pathConstraints',defFhPCon,@oclIsFunHandle);
      p.addOptional('boundaryConditions',defFhBC,@oclIsFunHandle);
      p.addOptional('discreteCosts',defFhDC,@oclIsFunHandle);
      
      p.parse(varargin{:});
      
      self.T = p.Results.T;
      self.fh.pathCosts = p.Results.pathCosts;
      self.fh.arrivalCosts = p.Results.arrivalCosts;
      self.fh.pathConstraints = p.Results.pathConstraints;
      self.fh.boundaryConditions = p.Results.boundaryConditions;
      self.fh.discreteCosts = p.Results.discreteCosts;

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

