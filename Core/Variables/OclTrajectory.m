classdef OclTrajectory < OclStructure
  % OCLTRAJECTORY Represents a trajectory of a variable
  %   Usually comes from selecting specific variables in a tree 
  properties
    positionArray
    type
  end
  
  methods
    function self = OclTrajectory(type,positionArray)
      if isa(type,'OclTrajectory')
        type = type.type;
      end
      self.type = type;
      self.positionArray = positionArray;
    end
    
    function [p,N,M,K] = getPositions(self)
      p = cell2mat(self.positionArray);
      s = self.type.size();
      N = s(1);
      M = s(2);
      K = length(self.positionArray);
      
      % squeeze dimensions of length 1
      p = reshape(p,[N,M,K]);
      p = squeeze(p);
      [N,M,K] = size(p);
      p = reshape(p,[N*M,K])';
      p = mat2cell(p,ones(K),N*M);
    end
    
    function s = size(self)
      l = length(self.positionArray);
      s = [prod(self.type.size),l];
    end
    
    function add(self,positions)
      self.positionArray{end+1} = positions;
    end
    
    function r = get(self,in, p)
      % r = get(selector)
      % r = get(id)
      positions = self.positionArray();
      if ischar(in)
        % in=id
        p = OclStructure.merge(positions,self.type.get(in).positionArray);
        if length(p) == 1 && isa(self.type,'OclTree')
          r = OclTree();
          obj = self.type.get(in);
          obj.positions = p{1};
          r.add(in,obj);
        elseif length(in)==1 && isa(self.type,'OclMatrix') 
          r = OclMatrix(p{1});
        else
          r = OclTrajectory(self.type.get(in).type,p);
        end
      else
        %in=selector
        r = OclTrajectory(self.type,positions(in));
      end
    end   
  end % methods
end % class

