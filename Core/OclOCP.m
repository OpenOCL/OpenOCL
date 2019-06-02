% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    pathcostsfh
    pointcostsfh
    pointconstraintsfh
  end
  
  methods(Access = public)
    function self = OclOCP(varargin)
      % OclOCP(pathCostsFH,arrivalCostsFH,pathConstraintsFH,discreteCostsFH)
      
      emptyfh = @(varargin)[];
      
      p = inputParser;
      p.addOptional('pathcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pointcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pointconstraintsOpt',[],@oclIsFunHandleOrEmpty);
      
      p.addParameter('pathcosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pointcosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pointconstraints',emptyfh,@oclIsFunHandle);
      p.parse(varargin{:});
      
      pathcostsfh = p.Results.pathcostsOpt;
      if isempty(pathcostsfh)
        pathcostsfh = p.Results.pathcosts;
      end
      
      pointcostsfh = p.Results.pointcostsOpt;
      if isempty(pointcostsfh)
        pointcostsfh = p.Results.pointcosts;
      end
      
      pointconstraintsfh = p.Results.pointconstraintsOpt;
      if isempty(pointconstraintsfh)
        pointconstraintsfh = p.Results.pointconstraints;
      end

      self.pathcostsfh = pathcostsfh;
      self.pointcostsfh = pointcostsfh;
      self.pointconstraintsfh = pointconstraintsfh;
    end

  end
end

