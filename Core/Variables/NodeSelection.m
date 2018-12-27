classdef NodeSelection < VarStructure
  % NODESELECTION Uniform selection of variables
  %   Usually comes from selecting specific variables in a tree 
  
  properties
    thisPositions
    nodeType
  end
  
  methods
    
    function self = NodeSelection(nodeType,positions)
      self.nodeType = nodeType;
      self.thisPositions  = positions;
    end
    
    function s = size(self, varargin)
      l = length(self.positions);
      if l == 1
        if nargin > 1
          s = self.nodeType.size(varargin{1});
        else
          s = self.nodeType.size;
        end
          
      else
        s = [prod(self.nodeType.size),length(self.positions)];
      end
    end
    
    function childSelection = get(self,in1,in2)
      % childSelection = get(self,id,selector)
      % childSelection = get(self,id)
      % childSelection = get(self,selector)
      if nargin == 2 && ischar(in1)
        % args: id
        childSelection = self.nodeType.getWithPositions(in1,self.positions);
      elseif nargin == 2
        % args: selector
        positions = self.positions;
        childSelection = NodeSelection(self.nodeType,positions(in1));
      else
        % args: id,selector
        childSelection = self.nodeType.getWithPositions(in1,self.positions,in2);
      end
    end
    
    function r = positions(self)
      r = self.thisPositions;
    end
    
    function r = getChildPointers(self)
      r = self.nodeType.getChildPointers();
    end
    
  end % methods
end % class

