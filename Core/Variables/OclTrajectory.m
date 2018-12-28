classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  
  properties
    % thisPositions from OclStructure
    nodeType
  end
  
  methods
    
    function self = OclTrajectory(nodeType,positions)
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
    
    function r = get(self,in1,in2)
      % r = get(self,id,selector)
      % r = get(self,id)
      % r = get(self,selector)
      if nargin == 2 && ischar(in1) && ~strcmp(in1,'end')
        % args: id
        r = self.nodeType.getWithPositions(in1,self.positions);
      elseif nargin == 2
        % args: selector
        positions = self.positions();
        if strcmp(in1,'end')
          in1 = length(positions);
        end
        assert(isnumeric(in1), 'Trajectory.get:Argument needs to be an index or char.')
        if length(in1) == 1 && isa(self.nodeType,'OclTree')
          r = OclTree(self.nodeType,positions(in1));
        elseif length(positions)==1 && isa(nodeType,'OclMatrix') 
          r = OclMatrix(self.nodeType.size,positions);
        else
          r = OclTrajectory(self.nodeType,positions(in1));
        end
      else
        % args: id,selector
        assert(ischar(in1), 'OclTrajectory.get:First argument needs to be an id.')
        r = self.nodeType.getWithPositions(in1,self.positions,in2);
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

