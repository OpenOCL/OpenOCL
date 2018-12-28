classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    % positions (OclStructure)
    type
  end
  
  methods
    function self = OclTrajectory(type,positions)
      self.type = type;
      self.positions = positions;
    end
    
    function s = size(self)
      l = length(self.positions);
      s = [prod(self.nodeType.size),l];
    end
    
    function r = get(self,idx)
      % r = get(self,idx)

      positions = self.positions();
      if strcmp(idx,'end')
        idx = length(positions);
      end
      assert(isnumeric(idx), 'Trajectory.get:Argument needs to be an index or char.')
      
      if length(idx) == 1 && isa(self.nodeType,'OclTree')
        r = OclTree(self.nodeType,positions(idx));
      elseif length(idx)==1 && isa(nodeType,'OclMatrix') 
        r = OclMatrix(self.nodeType.size,positions);
      else
        r = OclTrajectory(self.nodeType,positions(idx));
      end
    end   
  end % methods
end % class

