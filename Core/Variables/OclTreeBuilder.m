classdef OclTreeBuilder < OclBranch
  
  properties
    len
  end
  
  methods
  
    function self = OclTreeBuilder()
      self@OclBranch(OclTreeNode(struct,[]),{});
      self.len = 0;
    end
    
    function s = shape(self)
      s = [self.len 1];
    end
    
    function add(self,id,in2)
      % add(id)
      % add(id,length)
      % add(id,size)
      % add(id,branch)
      if nargin==2
        % add(id)
        node = OclTreeNode(struct, [1 1]);
        indizes = {self.len+1:self.len+1};
      elseif isnumeric(in2) && length(in2) == 1
        % args:(id,length)
        node = OclTreeNode(struct, [in2 1]);
        indizes = {self.len+1:self.len+in2};
      elseif isnumeric(in2)
        % args:(id,size)
        node = OclTreeNode(struct,[in2(1) in2(2)]);
        indizes = {self.len+1:self.len+prod(in2)};
      else
        % args:(id,branch)
        branch = in2;
        node = branch.node;
        indizes = {self.len+1:self.len+prod(node.shape)*length(branch)};
      end
      self.addBranch(id,node,indizes);
    end
    
    function addRepeated(self,ids,objList,N)
      % addRepeated(self,ids,objList,N)
      %   Adds repeatedly a list of structure objects
      %     e.g. ocpVar.addRepeated({'states','controls'},{stateStructure,controlStructure},20);
      for i=1:N
        for j=1:length(objList)
          self.add(ids{j},objList{j})
        end
      end
    end
    
    function addNode(self,id,n)
       N = prod(n.shape);
       
       if ~isfield(self.node.branches, id)
        self.node.branches.(id) = OclBranch(n, {self.len+1:self.len+N});
       else
        self.node.branches.(id).indizes{end+1} = self.len+1:self.len+N;
       end
       
       self.len = self.len + N;
       self.node.shape = [self.len 1];
       self.indizes = {1:self.len};
    end
    
    function addBranch(self,id,node,indizes)
      
      branch = OclBranch(node,indizes);
      
      s = branch.node.shape;
      N = length(branch.indizes)*prod(s);
      
      if ~isfield(self.node.branches, id)
        self.node.branches.(id) = OclBranch(branch.node, branch.indizes);
      else
        self.node.branches.(id).indizes = [self.node.branches.(id).indizes branch.indizes];
      end
      self.len = self.len + N;
      self.node.shape = [self.len 1];
      self.indizes = {1:self.len};
    end
    
  end % methods
end % classdef