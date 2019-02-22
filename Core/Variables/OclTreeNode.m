classdef OclTreeNode < handle
  
  properties
    branches
    shape
  end
  
  methods
    
    function self = OclTreeNode(branches,shape)
      self.branches = branches;
      self.shape = shape;
    end
    
    function r = get(self, id)
      r = self.branches.(id);
    end
    
    function r = hasBranches(self)
      r = ~isempty(fieldnames(self.branches));
    end
    
  end
end