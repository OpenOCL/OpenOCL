% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    lagrangecostsfh
    pathcostsfh
    pathconfh
  end
  
  methods(Access = public)
    function self = OclOCP(varargin)
      % OclOCP(pathCostsFH,arrivalCostsFH,pathConstraintsFH,discreteCostsFH)
      
      emptyfh = @(varargin)[];
      
      p = inputParser;
      p.addOptional('lagrangecostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pathcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pathconstraintsOpt',[],@oclIsFunHandleOrEmpty);
      
      p.addParameter('lagrangecosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pathcosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pathconstraints',emptyfh,@oclIsFunHandle);
      p.parse(varargin{:});
      
      lagrangecostsfh = p.Results.lagrangecostsOpt;
      if isempty(lagrangecostsfh)
        lagrangecostsfh = p.Results.lagrangecosts;
      end
      
      pathcostsfh = p.Results.pathcostsOpt;
      if isempty(pathcostsfh)
        pathcostsfh = p.Results.pathcosts;
      end
      
      pathconfh = p.Results.pathconstraintsOpt;
      if isempty(pathconfh)
        pathconfh = p.Results.pathconstraints;
      end

      self.lagrangecostsfh = lagrangecostsfh;
      self.pathcostsfh = pathcostsfh;
      self.pathconfh = pathconfh;
    end

  end
end

