classdef NodeSelection < handle
  %SUBEXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    parent
    positions
    varType
  end
  
  methods
    
    function self = NodeSelection(varType,parent,positions)
      
      self.varType = varType;

      self.parent     = parent;
      self.positions  = positions;
    end
    
    function r = get(self,id,selector)
      
      r = self.varType.get(id,selector);
      
    end
    
    function r = getIndizes(self,slicesIn)
      
      if nargin == 1
        slices = mergeSlices(self);
      else
        slices = mergeSlices(self,slicesIn);
      end
      
      r = self.parent.getIndizes(slices);
      
    end
    
  end
  
  methods (Access = private)
    
    function slices = mergeSlices(self,slicesIn)
      % slices = mergeSlices(self,slicesIn)
      
      varLength = prod(self.varType.size);
      if nargin == 1
        slicesIn = {1:varLength};
      end
            
      NPositions = length(self.positions);
      
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
      
    end
    
  end
  
end

