classdef OclValueStorage < handle
  % OCLVALUESTORAGE Class for storing values (numeric or symbolic)
  properties
    storage
  end
  
  methods (Static)
    
    function vs = allocate(type,l)
      % allocate(type,length)
      if isa(type,'casadi.MX')
        v = casadi.MX.zeros(l,1);
        vs = OclValueStorage(v);
      elseif isa(type,'casadi.SX')
        v = casadi.SX.zeros(l,1);
        vs = OclValueStorage(v);
      else
        v = zeros(l,1);
        vs = OclValueStorage(v);
      end
    end
    
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
    function self = OclValueStorage(v)
      narginchk(1,1); 
      self.storage = v;
    end
    
    function r = numel(self)
      r = numel(self.storage);
    end
    
    function set(self,type,value)
      % set(type,positions,value)
      if ~iscell(value)
        % value is numeric or casadi
%         shape = type.shape;
%         valShape = size(value);
        if isempty(value) || numel(value)==0
          return
        end
        
%         indizes = reshape(type.indizes,shape);
%         [shape,valShape] = broadCastShape(shape,valShape);
%         indizes = broadCastTo(indizes,shape);
%         value = broadCastTo(value,valShape);
        
        self.storage([type.indizes{:}]) = value(:);
      else
        % value is cell array
        % assign on third dimension (trajectory)
        
        shape = type.shape;
        indizes = reshape(type.indizes,shape);
        s = size(indizes);
        
        assert(length(value)==s(3));
        for k=1:s(end)
          idz = indizes(:,:,k);
          v = value{k};
          self.storage(idz(:)) = v(:);
        end
      end
    end % set
    
    function vout = value(self,type)
      % v = value(type)   
      vout = cell(1,length(type.indizes));
      shape = [type.shapes{1:end-1}];
      if length(shape) > 2
        shape(shape==1) = [];
      end
      if length(shape) == 1
        shape = [shape 1];
      end
      if isempty(shape)
        shape = [1 1];
      end
      for k=1:length(type.indizes)
        v = self.storage(type.indizes{k});
        v = reshape(v,shape);
        vout{k} = v;
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
  end
end

