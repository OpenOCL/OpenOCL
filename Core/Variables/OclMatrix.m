classdef OclMatrix < OclStructure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    % positions (OclStructure)
  end
  
  methods
    
    function self = OclMatrix(in1)
      % OclMatrix(size)
      % OclMatrix(positions)
      
      if isnumeric(in1)
        % in1=size
        assert(length(in1)<=2)
        self.positions = reshape(1:prod(in1),in1);
      else
        % in2=positions
        assert(iscell(in1))
        self.positions = in1;
      end
    end
    
    function s = size(self,dim)
      % s = size()
      % s = size(dim)
      s = size(self.positions{1});
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
      pos = self.positions{1};
      if nargin == 2
        pos = pos(dim1);
      else
        pos = pos(dim1,dim2);
      end
      r = OclMatrix(size(pos), {pos});
    end
  end
end

