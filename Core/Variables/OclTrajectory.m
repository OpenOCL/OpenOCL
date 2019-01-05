classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    positionArray
  end
  
  methods
    function self = OclTrajectory()
      self.positionArray = [];
    end
    
    function add(self,pos)
      
      if nargin==1 && ~isempty(self.positionArray)
        p = self.positionArray(:,:,end);
        pos = p+numel(p);
      elseif nargin==1
        pos = reshape(1:numel(pos),size(pos));
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
    
    function [r1,r2,r3] = size(self)
      if isempty(self.positionArray)
        s = [0,0];
        K = 0;
      else
        s = size(self.positionArray(:,:,1));
        K = size(self.positionArray,3);
      end
      if nargout==1
        r1 = [s,K];
      else
         r1 = s(1);
         r2 = s(2);
         r3 = K;
      end
    end
  end % methods
end % class

