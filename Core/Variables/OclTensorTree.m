classdef OclTensorTree < OclTensorType
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    len
  end

  methods
    function self = OclTensorTree()
      % OclTree()
      narginchk(0,0);
      self.children = [];
      self.len = 0;
    end
    
    function r = get(self,id,parentIndizes,parentShapes)
      % get(id)
      if nargin==2
        parentIndizes = {1:self.len};
        parentShapes = {1};
      end
      child = self.children.(id);
      indizes = self.merge(parentIndizes, child.indizes);
      shapes = [child.shapes parentShapes{2:end}];
      r = TensorChild(child.tensor,indizes,shapes);
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
      s1 = length(p1);
      s2 = length(p2);
      
      pout = cell(1,s1*s2);
      for k=1:s1
       ap1 =  p1{k};
       for l=1:s2
         pout{l+(k-1)*s2} = ap1(p2{l});
       end
      end
    end % merge
    

    function tree = flat(self)
      tree = OclTensorTreeBuilder();
      self.iterateLeafs({1:self.len},{self.len},tree);
    end
    
    
    function iterateLeafs(self,indizes,shapes,treeOut)
      childrenIds = fieldnames(self.children);
      for k=1:length(childrenIds)
        id = childrenIds{k};
        child = self.get(id,indizes,shapes);
        if isempty(child.tensor.children)
          s = [child.shapes{2:end}];
          treeOut.addObject(id,child.tensor,child.indizes, [ child.shapes(1),{prod(s)} ] );
        else
          child.tensor.iterateLeafs(child.indizes,child.shapes,treeOut);
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



