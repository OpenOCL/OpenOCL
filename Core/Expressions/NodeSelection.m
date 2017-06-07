classdef NodeSelection < VarStructure
  %SUBEXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    thisPositions
    nodeType
  end
  
  methods
    
    function self = NodeSelection(nodeType,positions)
      
      self.nodeType = nodeType;
      self.thisPositions  = positions;
    end
    
    function s = size(self)
      l = length(self.positions);
      if l == 1
        s = self.nodeType.size;
      else
        s = [prod(self.nodeType.size),length(self.positions)];
      end
    end
    
    function childSelection = get(self,id,selector)
      
      if nargin == 2
        childSelection = self.nodeType.getWithPositions(id,self.positions);
      else
        childSelection = self.nodeType.getWithPositions(id,self.positions,selector);
      end

    end
    
    function r = positions(self)
      r = self.thisPositions;
    end
    
  end

  
end

