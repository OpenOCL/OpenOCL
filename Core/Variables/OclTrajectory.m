classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    positionArray
    type
    len
  end
  
  methods
    function self = OclTrajectory(type)
      
      narginchk(1,1)
      self.type = type;
      self.len = 0;
      self.positionArray = [];
    end
    
    function [tout,pout] = get(self,pos,index)
      % [r,p] = get(selector)
      tout = OclTrajectory(self.type);
      pout = pos(index);
    end   
    
    function [N,M,K] = size(self)
      K = length(self.positionArray);
      s = self.type.size();
      if nargout==1
        N = [s,K];
      else
         N = s(1);
         M = s(2);
      end
    end
  end % methods
end % class

