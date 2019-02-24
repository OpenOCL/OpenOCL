classdef OclTreeBuilder < OclRootNode
  
  properties
    len
  end
  
  methods
  
    function self = OclTreeBuilder()
      self@OclRootNode(struct,[0 1],{});
      self.len = 0;
    end
    
    function add(self,id,in2)
      % add(id)
      % add(id,length)
      % add(id,size)
      % add(id,branch)
      if nargin==2
        % add(id)
        node = OclRootNode(struct, [1 1], {self.len+1:self.len+1});
      elseif isnumeric(in2) && length(in2) == 1
        % args:(id,length)
        node = OclRootNode(struct, [in2 1], {self.len+1:self.len+in2});
      elseif isnumeric(in2)
        % args:(id,size)
        node = OclRootNode(struct,[in2(1) in2(2)], {self.len+1:self.len+prod(in2)});
      else
        % args:(id,branch)
        node = OclRootNode(in2.branches,in2.shape,{self.len+1:self.len+prod(in2.shape)*length(in2)});
      end
      self.addNode(id,node);
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
    
    function addNode(self,id,node)
      
      N = nel(node);
      
      if ~isfield(self.branches, id)
        self.branches.(id) = node;
      else
        branch = self.branches.(id);
        branch.indizes(end+1:end+length(node.indizes)) = node.indizes;
      end
      self.len = self.len + N;
      self.shape = [self.len 1];
      self.indizes = {1:self.len};
    end
    
  end % methods
end % classdef