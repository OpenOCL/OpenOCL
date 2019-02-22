classdef OclRootNode < handle
  % OCLROOTNODE Basic datatype represent variables in a tree like structure.
  %
  properties
    branches
    shape
    indizes
  end

  methods
    function self = OclRootNode(branches,shape,indizes)
      % OclBranches()
      assert(length(shape)>1)
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
    
    function s = size(self)
      s = self.shape;
      if isempty(s) || length(self) > 1
        s = [s length(self)];
      end
    end
    
    function r = numel(self)
      r = prod(self.size());
    end
    
    function b = get(self,id)
      % get(id)
      b = self.branches.(id);
      idz = oclMergeArrays(self.indizes,b.indizes);
      b = OclRootNode(b.branches,b.shape,idz);
    end
    
  end % methods
end % class



