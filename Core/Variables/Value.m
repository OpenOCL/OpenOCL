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
    
    function set(self,type,pos,value)
      % set(type,positions,value)
      % set(type,positions,value)      
      pos = squeeze(pos);
      value = squeeze(value);
      [Np,Mp,Kp] = size(pos);
      [Nv,Mv] = size(value);
      
      if isempty(value) || Nv*Mv==0
        return
      end

      Nv = size(value,1);
      Mv = size(value,2);
      for k=1:Kp
        p = pos(:,:,k);
        self.val(p) = repmat(value,Np/Nv,Mp/Mv);
      end      
    end % set
    
    function vout = value(self,type,positions,varargin)
      % v = value(type,positions)

      % remove dimensions of length 1	
      p = squeeze(positions);      

      vout = cell(1,size(p,3));
      for k=1:size(p,3)
        vout{k} = reshape(self.val(p(:,:,k)),size(p(:,:,k)));
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
    
    function [p,N,M,K] = squeeze23(self,p,N,M,K)
       % squeeze dimensions of length 1
       p = reshape(p,[N,M,K]);
       p = squeeze(p);
       [N,M,K] = size(p);
       p = reshape(p,[N*M*K,1]);
    end
  end
end

