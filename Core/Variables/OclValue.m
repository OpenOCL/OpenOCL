classdef OclValue < handle
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
    function self = OclValue(v)
      narginchk(1,1); 
      self.val = v;
    end
    
    function r = numel(self)
      r = numel(self.val);
    end
    
    function set(self,type,value)
      % set(type,positions,value)
      if ~iscell(value)
        % value is numeric or casadi
        shape = type.shape;
        valShape = size(value);
        if isempty(value) || prod(valShape)==0
          return
        end
        
        indizes = reshape(type.indizes,shape);
%         [shape,valShape] = broadCastShape(shape,valShape);
%         indizes = broadCastTo(indizes,shape);
%         value = broadCastTo(value,valShape);
        
        self.val(indizes) = value;
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
          self.val(idz(:)) = v(:);
        end
      end
    end % set
    
    function vout = value(self,type)
      % v = value(type)   
      vout = cell(1,length(type.indizes));
      shape = [type.shapes{1:end-1}];
      shape(shape==1) = [];
      if length(shape) == 1
        shape = [shape 1];
      end
      for k=1:length(type.indizes)
        v = self.val(type.indizes{k});
        v = reshape(v,shape);
        vout{k} = v;
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
  end
end

