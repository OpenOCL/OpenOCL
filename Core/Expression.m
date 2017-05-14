classdef Expression < Arithmetic & TreeVar
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    treeVar
  end
  
  methods
    
    function self = Expression(treeVar)
      self.treeVar = treeVar;
    end
    
    function e = get(self,id,selector)
      [subVar,indizes] = self.treeVar.get(id,selector);
      sizes = self.treeVar.getSizes();
      
      positions = [];
      
      pos = 1;
      for k=1:length(sizes)
        
        if k == indizes(1)
          positions = [positions,pos];
          indizes(1) = [];
          if isempty(indizes)
            break
          end
        end

        pos = pos + prod(sizes{k});
      end
      
      e = SubExpression(subVar,self,positions);
    end
    
    function set(self,valueIn,sliceIn)
      
      if isscalar(valueIn)
        valueIn = valueIn * ones(1,prod(self.size));
      end
      
      if nargin == 2
        self.thisValue = valueIn';
      else
        for k=1:length(sliceIn)
          slice = sliceIn{k};
          self.thisValue(sliceIn{k}) = valueIn(slice-slice(1)+1);
        end
      end
      
    end
    
    function s = size(self)
      s = self.treeVar.size;
    end
    
    function v = value(self,sliceIn)
      
      if nargin == 2
        v = [];
        for k=1:length(sliceIn)
          v = [v;self.thisValue(sliceIn{k})];
        end
        v = v';
      else
        v = self.thisValue';
      end
      
    end
    
  end
  
end

