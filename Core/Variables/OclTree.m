classdef OclTree < OclStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    positions
    len
  end

  methods
    function self = OclTree()
      % OclTree()
      narginchk(0,0);
      self.children = struct;
      self.positions = struct;
      self.len = 0;
    end
    
    function s = size(self)
      s = [1,self.len];
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
    
    function addObject(self,id,obj,pos)
      % addVar(id, obj)
      %   Adds a structure object
      
      objLength = prod(obj.size);
      if nargin==3
        pos = {self.len+1:self.len+objLength};
      end
      
      N = length(pos);
      if isfield(self.children, id)
        self.positions.(id) = cat(2,self.positions.(id),pos);
      else
        self.children.(id) = OclTrajectory(obj);
        self.positions.(id) = pos;
      end
      self.children.(id).add(N);
      self.len = self.len+objLength*N;
    end
    
    function [t,p] = get(self,pos,id)
      % get(pos,id)
      t = self.children.(id);
      p = self.positions.(id);
      p = OclTree.merge(pos,p);
    end
    
    function [pos,N,M,K] = getPositions(self,pos)
      N = self.len;
      M = 1;
      K = 1;
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
        elseif isa(child,'OclTrajectory')
          if isa(child.type,'OclMatrix')
            treeOut.addObject(id,child.type,pos);
          elseif isa(child.type,'OclTree')
            child.type.iterateLeafs(pos,treeOut);
          else
            oclError('Children of a trajectory can not be a trajectory');
          end
        end
      end % for
    end % iterateLeafs
  end % methods
end % class



