classdef SubExpression < ExpressionBase
  %SUBEXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    parent
    positions
  end
  
  methods
    
    function self = SubExpression(treeVar,parent,positions)
      self = self@ExpressionBase(treeVar);
      self.parent     = parent;
      self.positions  = positions;
    end
    
    function set(self,valueIn,slicesIn)
      
      varLength = prod(self.treeVar.size);
      NPositions = length(self.positions);
      
      if nargin == 2
        slicesIn = {1:varLength};
      end

      slices = cell(1,NPositions*length(slicesIn));
      i = 1;
      for k=1:NPositions
        pos = self.positions(k);
        slice = pos:pos+varLength-1;
        
        for l=1:length(slicesIn)
          slices{i} = slice(slicesIn{l});
        end
        i = i+1;
      end
      
      self.parent.set(valueIn,slices)
    end
    
    function v = value(self,slicesIn,varIn)
      
      varLength = prod(self.treeVar.size);
      NPositions = length(self.positions);
      
      if nargin == 1
        slicesIn = {1:varLength};
        varIn = self;
      end

      slices = cell(1,NPositions*length(slicesIn));
      i = 1;
      for k=1:NPositions
        pos = self.positions(k);
        slice = pos:pos+varLength-1;
        
        for l=1:length(slicesIn)
          slices{i} = slice(slicesIn{l});
        end
        i = i+1;
      end
      
      v = self.parent.value(slices,varIn);
    end
    
  end
  
end

