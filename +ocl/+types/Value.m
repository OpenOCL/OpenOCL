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
      if ~iscell(value)
        % value is numeric or casadi
        pos = ocl.types.Value.squeeze(pos);
        value = ocl.types.Value.squeeze(value);
        [Np,Mp,Kp] = size(pos);
        [Nv,Mv] = size(value);
        if isempty(value) || Nv*Mv==0
          return
        end

        if mod(Np,Nv)~=0 || mod(Mp,Mv)~=0
          oclError('Can not set values to variable. Dimensions do not match.')
        end
        
        for k=1:Kp
          p = pos(:,:,k);
          self.val(p) = repmat(value,Np/Nv,Mp/Mv);
        end   
      else
        % value is cell array
        Kp = size(pos,3);
        assert(length(value)==Kp);
        for k=1:Kp
          p = pos(:,:,k);
          self.val(p) = value{k};
        end
      end
    end % set
    
    function vout = value(self,~,positions,varargin)
      % v = value(type,positions)
      p = squeeze(positions);      
      vout = cell(1,size(p,3));
      for k=1:size(p,3)
        vout{k} = reshape(self.val(p(:,:,k)),size(p(:,:,k)));
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
  end
end

