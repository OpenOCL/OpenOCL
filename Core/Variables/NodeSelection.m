classdef NodeSelection < VarStructure
  % NODESELECTION Uniform selection of variables
  %   Usually comes from selecting specific variables in a tree 
  
  properties
    % thisPositions from VarStructure
    nodeType
  end
  
  methods
    
    function self = NodeSelection(nodeType,positions)
      self.nodeType = nodeType;
      self.thisPositions  = positions;
      
      if length(positions)==1 && isa(nodeType,'MatrixStructure') 
        self = MatrixStructure(nodeType.size,positions);
        return
      end
            
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
      if nargin == 2 && ischar(in1) && ~strcmp(in1,'end')
        % args: id
        childSelection = self.nodeType.getWithPositions(in1,self.positions);
      elseif nargin == 2
        % args: selector
        positions = self.positions();
        if strcmp(in1,'end')
          in1 = length(positions);
        end
        assert(isnumeric(in1), 'NodeSelection.get:Argument needs to be an index or char.')
        if length(in1) == 1 && isa(self.nodeType,'TreeNode')
          childSelection = TreeNode(self.nodeType,positions(in1));
        else 
          childSelection = NodeSelection(self.nodeType,positions(in1));
        end
      else
        % args: id,selector
        assert(ischar(in1), 'NodeSelection.get:First argument needs to be an id.')
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

