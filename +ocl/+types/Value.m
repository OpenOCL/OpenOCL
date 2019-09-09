% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Value < handle
  % OCLVALUE Class for storing values (numeric or symbolic)
  properties
    val
  end
  
  methods (Static)
    function r = squeeze(matrix)
       % totally! squeeze dimensions of length 1
        r = squeeze(matrix);
        if size(r,1) == 1
          s = size(r);
          r = reshape(r,[s(2:end) 1]);
        end
    end
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
      
      if isa(type, 'ocl.types.Matrix') && all(type.msize == size(value))
        for k=1:size(pos,2)
          p = reshape(pos(:,k), type.msize);
          self.val(p) = value; 
        end
        return;
      end
      
      if isa(type, 'ocl.types.Matrix') && size(pos,2)==1
        pos = reshape(pos, type.msize);
      end

      % value is numeric or casadi
      [Np,Mp] = size(pos);
      [Nv,Mv] = size(value);
      if isempty(value) || Nv*Mv==0
        return
      end

      if mod(Np,Nv)~=0 || mod(Mp,Mv)~=0
        ocl.utils.error('Can not set values to variable. Dimensions do not match.')
      end
      
      self.val(pos) = repmat(value,Np/Nv,Mp/Mv);
      
    end % set
    
    function vout = value(self,type,positions,varargin)
      % v = value(type,positions)
      p = positions;
      vout = reshape(self.val(p),size(p));
      if isa(type, 'ocl.types.Matrix') && size(p,2)==1
        vout = reshape(vout, type.msize);
      end
    end
  end
end

