classdef OclMatrix < OclStructure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    % positions (OclStructure)
  end
  
  methods
    
    function self = OclMatrix(in)
      % OclMatrix(size)
      % OclMatrix(positions)
      
      if isnumeric(in)
        % in=size
        self.positions = reshape(1:prod(in),in);
      else
        % in=positions
        self.positions = in;
      end
    end
    
    function s = size(self,dim)
      % s = size()
      % s = size(dim)
      s = size(self.positions);
      if nargin == 2
        if dim <= 2
          s = s(dim)
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
      r = OclMatrix(size(pos), pos);
    end
  end
end

