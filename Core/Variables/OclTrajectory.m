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
      s = [prod(self.type.size),l];
    end
    
    function r = get(self,in)
      % r = get(selector)
      % r = get(id)
      
      positions = self.positions();
      if ischar(in)
        % in=id
        p = OclStructure.merge(positions,self.type.get(in).positions);
        r = OclTrajectory(self.type.get(in).type,p);
      else
        %in=selector
        if length(in) == 1 && isa(self.type,'OclTree')
          r = OclTree(positions(in));
        elseif length(in)==1 && isa(type,'OclMatrix') 
          r = OclMatrix(positions(in);
        else
          r = OclTrajectory(self.type,positions(in));
        end
      end
    end   
  end % methods
end % class

