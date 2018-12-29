classdef OclMatrix < OclStructure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    positions
    msize
  end
  
  methods
    
    function self = OclMatrix(s,p)
      % OclMatrix(size)
      % OclMatrix(size,positions)
      
      self.msize = s;
      self.positions = reshape(1:prod(s),s);
        
      if nargin == 2
        % in2=positions
        self.positions = p;
      end
    end
    
    function [p,N,M,K] = getPositions(self)
      p = {reshape(self.positions,[self.msize])};
      s = self.size();
      N = s(1);
      M = s(2);
      K = 1;
    end
    
    function r = size(self)
      r = self.msize;
    end
    
    function r = get(self,dim1,dim2)
      % get(dim1)
      % get(dim1,dim2)
      pos = self.positions;
      if nargin == 2
        pos = pos(dim1);
      else
        pos = pos(dim1,dim2);
      end
      r = OclMatrix(size(pos),pos);
    end
  end
end

