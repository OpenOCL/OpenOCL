classdef OclBranch < handle
  % OCLBRANCH Basic datatype represent variables in a tree like structure.
  %
  properties
    branches
    shape
    indizes
  end

  methods
    function self = OclBranch(branches,shape,indizes)
      % OclBranches()
      self.branches = branches;
      self.shape = shape;
      self.indizes = indizes;
    end
    
    function r = hasBranches(self)
      r = ~isempty(fieldnames(self.branches));
    end
    
    function l = length(self)
      l = length(self.indizes);
    end
    
    function b = get(self,id)
      % get(id)
      b = self.branches.(id);
      idz = oclMergeArrays(self.indizes,b.indizes);
      b = OclBranch(b.branches,b.shape,idz);
    end
    
  end % methods
end % class



