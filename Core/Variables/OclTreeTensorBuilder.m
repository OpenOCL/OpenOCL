classdef OclTreeTensorBuilder < OclTreeTensor
  
  properties
  end
  
  methods
  
    function self = OclTreeTensorBuilder()
    end
    
    function add(self,id,in2)
      % add(id)
      % add(id,length)
      % add(id,size)
      % add(id,obj)
      if nargin==2
        % add(id)
        tensor = OclTreeTensor();
        shape = [];
      elseif isnumeric(in2) && length(in2) == 1
        % args:(id,length)
        shape = in2;
        tensor = OclTreeTensor();
      elseif isnumeric(in2)
        % args:(id,size)
        shape = [in2(1) in2(2)];
        tensor = OclTreeTensor();
      else
        % args:(id,obj)
        shape = in2.size;
        tensor = in2;
      end
      indizes = {self.len+1:self.len+prod(shape)};
      self.addObject(id,tensor,indizes,shape);
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
    
    function addObject(self,id,tensor,indizes,shape)
      % addVar(id, structure, indizes, shape)
      %   Adds a child object from structure, indizes, shape
      
      self.len = self.len+length([indizes{:}]);
      
      if ~isfield(self.children, id)
        self.children.(id) = OclTensorRoot(tensor,indizes,shape);
      else
        K = length(indizes);
        self.children.(id).indizes(end+1:end+K) = indizes;
      end
    end
    
  end % methods
end % classdef