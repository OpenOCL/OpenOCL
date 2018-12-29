classdef OclMatrix < OclStructure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    positions
  end
  
  methods
    
    function self = OclMatrix(in1,in2)
      % OclMatrix(size)
      % OclMatrix(positions)
      
      if isnumeric(in1) && nargin==1
        % in1=size
        assert(length(in1)<=2)
        self.positions = reshape(1:prod(in1),in1);
      elseif ischar(in1) && isnumeric(in2)
        % in2=positions
        self.positions = in2;
      else
        error('OclMatrix invalid arguments.')
      end
    end
    
    function [p,N,M,K] = getPositions(self)
      p = {self.positions};
      s = self.size();
      N = s(1);
      M = s(2);
      K = 1;
    end
    
    function s = size(self,dim)
      % s = size()
      % s = size(dim)
      s = size(self.positions);
      if nargin == 2
        if dim <= 2
          s = s(dim);
        else
          s = 1;
        end
      end
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
      r = OclMatrix('p',pos);
    end
  end
end

