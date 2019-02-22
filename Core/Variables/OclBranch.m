classdef OclBranch < handle
  % OCLBRANCH Basic datatype represent variables in a tree like structure.
  %
  properties
    node
    indizes
  end

  methods
    function self = OclBranch(node,indizes)
      % OclBranches()
      self.node = node;
      self.indizes = indizes;
    end
    
    function l = length(self)
      l = length(self.indizes);
    end
    
    function n = getNode(self)
      % update all branch of node
      branchNames = fieldnames(self.node.branches);
      branches = struct;
      for i=1:length(branchNames)
        id = branchNames{i};
        b = self.node.branches.(id);
        idz = oclMergeArrays(self.indizes, b.indizes);
        branches.(id) = Branch(b.node,idz);
      end
      n = OclTreeNode(branches,self.node.shape);
    end
    
    function b = get(self,id)
      % get(id)
      n = self.node;
      b = n.get(id);
      
      idz = oclMergeArrays(self.indizes,b.indizes);
      b = OclBranch(b.node,idz);
    end
    
  end % methods
end % class



