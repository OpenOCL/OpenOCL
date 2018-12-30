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
      self.positionArray = {};
    end
    
    function s = size(self)
      s = [prod(self.type.size),length(self.positionArray)];
    end
    
    function add(self,N)
      narginchk(2,2);
      nEl = prod(self.type.size);
      for k=1:N
        self.positionArray{end+1} = self.len+1:self.len+nEl;
        self.len = self.len+nEl;
      end
    end
    
    function [tout,pout] = get(self,pos,in)
      % [r,p] = get(selector)
      % [r,p] = get(id)
      if ischar(in)
        [tout,pout] = getById(self,pos,in);
      else
        [tout,pout] = getByIndex(self,pos,in);
      end
    end   
    
    function [tout,pout] = getByIndex(self,pos,index)
      tout = OclTrajectory(self.type);
      pout = pos(index);
    end
    
    function [tout,pout] = getById(self,pos,id)
      tree = self.type;
      assert(isa(tree,'OclTree'));
      
      childPositions = tree.positions.(id);
      pout = OclStructure.merge(pos,childPositions); 
      tout = tree.children.(id);
    end
    
    function [p,N,M,K] = getPositions(self,pos)
       p = cell2mat(pos);
       s = self.type.size();
       N = s(1);
       M = s(2);
       K = length(pos);
    end
  end % methods
end % class

