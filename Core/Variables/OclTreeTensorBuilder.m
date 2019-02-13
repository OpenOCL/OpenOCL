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
        N = 1;
        M = 1;
        K = 1;
        tensor = OclTreeTensor();
        shape = [N,M];
      elseif isnumeric(in2) && length(in2) == 1
        % args:(id,length)
        N = in2;
        M = 1;
        K = 1;
        tensor = OclTreeTensor();
        shape = [N,M];
      elseif isnumeric(in2)
        % args:(id,size)
        N = in2(1);
        M = in2(2);
        K = 1;
        tensor = OclTreeTensor();
        shape = [N,M];
      else
        % args:(id,obj)
        [N,M,K] = in2.size;
        tensor = in2;
        shape = [N,M,K];
      end
      indizes = {self.len+1:self.len+N*M*K};
      self.addObject(id,tensor,indizes,{shape,1});
    end
    
    function addRepeated(self,names,arr,N)
      % addRepeated(self,arr,N)
      %   Adds repeatedly a list of structure objects
      %     e.g. ocpVar.addRepeated([stateStructure,controlStructure],20);
      for i=1:N
        for j=1:length(arr)
          self.add(names{j},arr{j})
        end
      end
    end
    
    function addObject(self,id,tensor,indizes,shapes)
      % addVar(id, structure, indizes, shape)
      %   Adds a child object from structure, indizes, shape
      
      self.len = self.len+length([indizes{:}]);
      
      if ~isfield(self.children, id)
        self.children.(id) = OclTensorRoot(tensor,indizes,shapes);
      else
        K = length(indizes);
        self.children.(id).indizes(end+1:end+K) = indizes;
        self.children.(id).shapes{end} = self.children.(id).shapes{end} + shapes{end};
      end
    end
    
  end % methods
end % classdef