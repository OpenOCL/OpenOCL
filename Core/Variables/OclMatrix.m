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
    
    function [r,p] = get(self,pos,varargin)
      % get(pos,dim1)
      % get(pos,dim1,dim2)
      % get(pos,dim1,dim2,dim3)
      [N,M,K] = size(pos);
      dims = varargin;
      if isempty(dims)
        dims = {1:N,1:M,1:K};
      end
      
      p = pos(dims{:});
      r = OclMatrix(size(p));
    end
    
    function [N,M,K] = size(self)
      s = self.msize();
      if nargout>1
        N = s(1);
        M = s(2);
        K = 1;
      else
        N = s;
      end
    end
    
  end
end

