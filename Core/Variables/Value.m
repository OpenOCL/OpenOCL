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
    
    function set(self,type,positions,value,varargin)
      % set(type,positions,value)
      % set(type,positions,value,slice1,slice2,slice3)      
      [pos,N,M,K] = type.getPositions(positions);
      pos = reshape(pos,[N,M,K]);
      
      assert(length(size(value)) <= 2, 'Only matrix values supported.');
      
      dims = [varargin{:}];
      if isempty(dims)
        dims = {1:N,1:M,1:K};
      end
      
      N = length(dims{1});
      M = length(dims{2});

      Nv = size(value,1);
      Mv = size(value,2);
      for k=dims{3}
        p = pos(:,:,k);
        self.val(p(dims{1},dims{2})) = repmat(value,N/Nv,M/Mv);
      end      
    end % set
    
    function vout = value(self,type,positions,varargin)
      % v = value(type,positions)
      % v = value(type,positions,slice1,slice2,slice3)
      p = self.slice(type,positions,varargin{:});
      vout = cell(1,length(p));
      for k=1:length(p)
        vout{k} = reshape(self.val(p{k}),size(p{k}));
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
       p = reshape(p,[N,M,K]);
       p = shiftdim(num2cell(p,[1,2]),1);
       assert(K==length(p))
    end
    
    function [pout,N,M,K] = slice(self,type,positions,dim1,dim2,dim3)
      [pos,N,M,K] = type.getPositions(positions);
      [pos,N,M,K] = self.squeeze(pos,N,M,K);
      
      pout = cell(1,K);
      for k=1:K
        p = reshape(pos{k},[N,M]);
        if nargin==4
          p = p(dim1);
        elseif nargin==5
          p = p(dim1,dim2);  
        end
        pout{k} = p;
      end
      if nargin==6
        pout = p(dim3);
      end
    end
  end
end

