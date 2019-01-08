classdef OclStructure < handle
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    len
  end

  methods
    function self = OclStructure()
      % OclTree()
      narginchk(0,0);
      self.children = struct;
      self.len = 0;
    end

    function add(self,id,in2)
      % add(id,size)
      % add(id,obj)
      if isnumeric(in2)
        % args:(id,size)
        N = in2(1);
        M = in2(2);
        K = 1;
        obj = OclMatrix([N,M]);
      else
        % args:(id,obj)
        [N,M,K] = in2.size;
        obj = in2;
      end
      pos = self.len+1:self.len+N*M*K;
      pos = reshape(pos,N,M,K);
      self.addObject(id,obj,pos);
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
      
      [N,M,K] = size(pos);
      self.len = self.len+N*M*K;
      
      if ~isfield(self.children, id)
        self.children.(id).type = obj;
        self.children.(id).positions = pos;
      else
        self.children.(id).positions(:,:,end+1:end+K) = pos;
      end
    end
    
    function [t,p] = get(self,id,pos)
      % get(pos,id)
      if nargin==2
        pos = (1:self.len).';
      end
      p = self.children.(id).positions;
      t = self.children.(id).type;
      p = self.merge(pos,p);
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

    function pout = merge(self,p1,p2)
      % merge(p1,p2)
      % Combine arrays of positions on the third dimension
      % p2 are relative to p1
      % Returns: absolute p2
      [~,~,K1] = size(p1);
      [N2,M2,K2] = size(p2);
      
      pout = zeros(N2,M2,K1*K2);
      for k=1:K1
       ap1 =  p1(:,:,k);
       for l=1:K2
         pout(:,:,l+(k-1)*K2) = ap1(p2(:,:,l));
       end
      end
    end % merge
    

    function tree = flat(self)
      tree = OclStructure();
      self.iterateLeafs((1:self.len).',tree);
    end
    
    
    function iterateLeafs(self,positions,treeOut)
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(id,positions);
        if isa(child,'OclMatrix')
          treeOut.addObject(id,child,pos);
        elseif isa(child,'OclStructure')
          child.iterateLeafs(pos,treeOut);
        end
      end
    end 
    
    
    function valueStruct = toStruct(self,value)
      valueStruct = struct;
      positions = (1:self.len).';
      valueStruct = self.iterateStruct(positions,value,valueStruct);
    end
    
    function [valueStruct,posStruct] = iterateStruct(self,positions,value,valueStruct)
      
      valueStruct.value = value(positions);
      valueStruct.positions = positions;
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(id,positions);
        if isa(child,'OclStructure')
          childValueStruct = child.iterateStruct(pos,value,valueStruct);
        end
        valueStruct.(id) = childValueStruct;
      end
      
    end
    
    
  end % methods
end % class



