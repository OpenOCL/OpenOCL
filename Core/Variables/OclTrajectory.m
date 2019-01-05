classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    positionArray
    type
  end
  
  methods
    function self = OclTrajectory(type)
      
      narginchk(1,1)
      self.type = type;
      self.positionArray = [];
    end
    
    function [tout,pout] = get(self,pos,index)
      % [r,p] = get(selector)
      tout = OclTrajectory(self.type);
      pout = pos(index);
    end   
    
    function add(self,pos)
      
      if nargin==1 && ~isempty(self.positionArray)
        p = self.positionArray(:,:,end);
        pos = p+numel(p);
      elseif nargin==1
        nel = prod(self.type.size());
        pos = reshape(1:nel,self.type.size);
      end
      
      if isempty(self.positionArray)
        self.positionArray = pos;
      else
        [~,~,K] = size(pos);
        self.positionArray(:,:,end+1:end+K) = pos;
        if K >1
          keyboard
        end
      end
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

