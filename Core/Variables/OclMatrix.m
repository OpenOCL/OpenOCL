classdef OclMatrix < OclStructure
  %OCLMATRIX Matrix valued structure for variables
  %
  properties
    msize
  end
  
  methods
    
    function self = OclMatrix(size)
      % OclMatrix(size)
      self.msize = size;
    end
    
    function [r,pos] = get(self,pos,varargin)
      % get(pos,dim1)
      % get(pos,dim1,dim2)
      pos = pos(varargin{:});
      r = OclMatrix(size(pos));
    end
    
    function [N,M,K] = size(self)
      s = self.msize();
      if nargout==1
        N = [s,1];
      else
        N = s(1);
        M = s(2);
        K = 1;
      end
    end
    
  end
end

