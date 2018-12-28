classdef MatrixStructure < VarStructure
  %MATRIXSTRUCTURE Matrix valued variables
  %   
  
  properties
    % thisPositions from VarStructure
  end
  
  methods
    
    function self = MatrixStructure(s, positions)
      % MatrixStructure(size, positions)
      
      self.thisSize = s;
      if nargin == 1
        self.thisPositions = {1:prod(self.size)};
      else
        self.thisPositions = positions;
      end
    end
    
    function s = size(self,varargin)
      % s = size()
      % s = size(dim)
      if nargin == 2
        if varargin{1} > 2
          s = 1;
        else
          s = self.thisSize(varargin{1});
        end
      else
        s = self.thisSize;
      end
    end
    
    function r = positions(self)
      r = self.thisPositions;
    end
    
    function r = get(self,dim1,dim2)
      pos = reshape(self.positions{1}, self.size);
      if nargin == 2
        pos = pos(dim1);
      else
        pos = pos(dim1,dim2);
      end
      s = size(pos);
      pos = pos(:)';
      r = MatrixStructure(s, {pos});
    end
    
    function r = getChildPointers(varargin)
      r = struct;
    end

    function subVar = getWithPositions(self,id,parentPositions,selector)
      parentPositions
      self.size
      id
      subVar = struct;
    end
  end
end

