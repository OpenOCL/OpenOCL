classdef OclTree < OclStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    types
    len
  end

  methods
    function self = OclTree()
      % OclTree()
      narginchk(0,0);
      self.children = struct;
      self.types = struct;
      self.len = 0;
    end

    function add(self,id,in2)
      % add(id,size)
      % add(id,obj)
      if isnumeric(in2)
        % args:(id,size)
        self.addMatrix(id,in2);
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
    
    function addMatrix(self,id,s)
      N = s(1);
      M = s(2);
      pos = self.len+1:self.len+N*M;
      pos = reshape(pos,N,M);
      self.addWithPositions(id,pos);
    end
    
    function addWithPositions(self,id,pos)
      [N,M,K] = size(pos);
      self.len = self.len+N*M*K;
      if ~isfield(self.children, id)
        self.children.(id) = OclTrajectory();
        self.types.(id) = OclTree();
      end
      self.children.(id).add(pos);
    end
    
    function addObject(self,id,obj,pos)
      % addVar(id, obj)
      %   Adds a structure object
      
      if nargin==3
        [N,M,K] = obj.size;
        pos = self.len+1:self.len+N*M*K;
        pos = reshape(pos,N,M,K);
        self.len = self.len+N*M*K;
      else
        [N,M,K] = size(pos);
        self.len = self.len+N*M*K;
      end
      if ~isfield(self.children, id)
        self.children.(id) = OclTrajectory(obj);
        self.types.(id) = obj;
      end
      self.children.(id).add(pos);
    end
    
    function [t,p] = get(self,id,pos)
      % get(pos,id)
      
      if nargin==2
        pos = (1:self.len).';
      end
      p = self.children.(id).getPositions(pos);
      t = self.children.(id);
    end
    
    function [N,M,K] = size(self)
      if nargout>1
        N = self.len;
        M = 1;
        K = 1;
      else
        N = [self.len,1];
      end
    end

    function tree = getFlat(self)
      tree = OclTree();
      self.iterateLeafs((1:self.len).',tree);
    end
    
    function iterateLeafs(self,positions,treeOut)
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(positions,id);
        if isa(child,'OclMatrix')
          treeOut.addObject(id,child,pos);
        elseif isa(child,'OclTree')
          child.iterateLeafs(pos,treeOut);
        end
      end
    end 
    
    function sizes = getMatrixSizes(self)
      sizes = {};
      pos = (1:self.len).';
      sizes = self.iterateSizes(pos,sizes);
    end
    
    function sizesOut = iterateSizes(self,positions,sizesOut)
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(positions,id);
        if isa(child,'OclMatrix')
          sizesOut{end+1} = size(pos);
        elseif isa(child,'OclTree')
          s = child.iterateSizes(pos,sizesOut);
          sizesOut{end+1} = size(pos);
        end
      end
    end 
    
  end % methods
end % class



