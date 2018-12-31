classdef Value < handle
  % VALUE Class for storing values
  properties
    val
  end
  methods
    function self = Value(v)
      narginchk(1,1); 
      self.val = v;
    end
    
    function r = numel(self)
      r = numel(self.val);
    end
    
    function set(self,type,pos,value,varargin)
      % set(type,positions,value)
      % set(type,positions,value,slice1,slice2,slice3)      
      [N,M,K] = size(pos);
      
      assert(length(size(value)) <= 2, 'Only matrix values supported.');

      Nv = size(value,1);
      Mv = size(value,2);
      for k=1:K
        p = pos(:,:,k);
        self.val(p) = repmat(value,N/Nv,M/Mv);
      end      
    end % set
    
    function vout = value(self,type,positions,varargin)
      % v = value(type,positions)
      p = positions();

      vout = cell(1,size(p,3));
      for k=1:size(p,3)
        vout{k} = reshape(self.val(p(:,:,k)),size(p(:,:,k)));
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
    
    function [p,N,M,K] = squeeze(self,p,N,M,K)
       % squeeze dimensions of length 1
       p = reshape(p,[N,M,K]);
       p = squeeze(p);
       [N,M,K] = size(p);
       p = reshape(p,[N*M*K,1]);
    end
    
    function [pout,N,M,K] = slice(self,type,pos,dim1,dim2,dim3)
      [N,M,K] = type.size();
      [pos,N,M,K] = self.squeeze(pos,N,M,K);
      
      pout = zeros(N,M,K);
      for k=1:K
        p = pos(:,:,k);
        if nargin==4
          p = p(dim1);
        elseif nargin==5
          p = p(dim1,dim2);  
        end
        pout(:,:,k) = p;
      end
      if nargin==6
        pout = p(:,:,dim3);
      end
    end
  end
end

