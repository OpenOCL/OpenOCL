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
      tree = OclStructureBuilder();
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
      positions = (1:self.len).';
      valueStruct = self.iterateStruct(positions,value);
    end
    
    function [valueStruct,posStruct] = iterateStruct(self,positions,value)
      
      valueStruct = struct;
      valueStruct.value = value(positions);
      valueStruct.positions = positions;
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        [child,pos] = self.get(id,positions);
        if isa(child,'OclStructure')
          childValueStruct = child.iterateStruct(pos,value);
          valueStruct.(id) = childValueStruct;
        end
      end
    end
    
    
  end % methods
end % class



