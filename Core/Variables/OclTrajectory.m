classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    positions
    children
    type
  end
  
  methods
    function self = OclTrajectory(type)
      self.positions = [];
      self.type = [];
      self.children = struct;
      if nargin==1
        self.type = type;
        self.children = type.children;
      end
    end
    
    function add(self,pos)
      
      if nargin==1 && ~isempty(self.positions)
        p = self.positions(:,:,end);
        pos = p+numel(p);
      elseif nargin==1
        pos = reshape(1:numel(pos),size(pos));
      end
      
      if isempty(self.positions)
        self.positions = pos;
      else
        [~,~,K] = size(pos);
        self.positions(:,:,end+1:end+K) = pos;
        if K >1
          keyboard
        end
      end
    end
    
    function [t,p] = get(self,id,pos)
      t = self.type.get(id);
      p = t.positions;
      p = OclTree.merge(pos,p);
    end
    
    function p = getPositions(self,pos)
      p = OclTree.merge(pos,self.positions);
    end
    
    function [r1,r2,r3] = size(self)
      if isempty(self.positions)
        s = [0,0];
        K = 0;
      else
        s = size(self.positions(:,:,1));
        K = size(self.positions,3);
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

