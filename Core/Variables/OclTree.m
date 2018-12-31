classdef OclTree < OclStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    len
  end

  methods
    function self = OclTree()
      % OclTree()
      narginchk(0,0);
      self.children = struct;
      self.len = 0;
    end

    function add(self,id,in2)
      % add(id,size)
      % add(id,obj)
      % add(id,obj,positions)
      if isnumeric(in2)
        % args:(id,size)
        self.addObject(id,OclMatrix(in2));
      else
        % args:(id,obj)
        self.addObject(id,in2);
      end
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
    
    function addObject(self,id,obj)
      % addVar(id, obj)
      %   Adds a structure object
      
      [N,M,K] = obj.size;
      pos = self.len+1:self.len+N*M*K;
      pos = reshape(pos,N,M,K);
      self.len = self.len+N*M*K;
      
      if ~isfield(self.children, id)
        self.children.(id) = OclTrajectory(obj);
        self.children.(id).positionArray = pos;
      else
        self.children.(id).positionArray(:,:,end+1) = pos;
      end
    end
    
    function [t,p] = get(self,pos,in3,in4)
      % get(pos,id)
      % get(pos,index)
      % get(pos,id,index)
      
      if nargin==3 && ischar(in3)
        t = self.children.(in3).type;
        p = self.children.(in3).positionArray;
        p = OclTree.merge(pos,p);
      elseif nargin == 3 && isnumeric(in3)
        t = self;
        p = pos(:,:,in3);
      else
        t = self.children.(in3).type;
        p = self.children.(in3).positionArray;
        p = p(:,:,in4);
        p = OclTree.merge(pos,p);
      end
      
    end
    
    function [N,M,K] = size(self)
      if nargout==1
        N = [self.len,1,1];
      else
        N = self.len;
        M = 1;
        K = 1;
      end
    end

    function tree = getFlat(self)
      tree = OclTree();
      self.iterateLeafs(1:self.len,tree);
    end
    
    function iterateLeafs(self,positions,treeOut)
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(positions,id);
        if isa(child,'OclMatrix')
          treeOut.addObject(id,child,pos);
        elseif isa(child,'OclTree')
          child.iterateLeafs(id,pos,treeOut);
        end
      end % for
    end % iterateLeafs
  end % methods
end % class



