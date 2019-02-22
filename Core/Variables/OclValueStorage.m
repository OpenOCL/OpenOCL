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
        if isempty(value) || numel(value)==0
          return
        end
        
        for k=1:length(type.indizes)
          idz = type.indizes{k};
          self.storage(idz) = value(:);
        end
      else
        % value is cell array

        for k=1:length(type.indizes)
          idz = type.indizes{k};
          v = value{k};
          self.storage(idz) = v(:);
        end
      end
    end % set
    
    function vout = value(self,type)
      % v = value(type)  
      
      s = type.shape;
      if length(s) == 1
        s = [s 1];
      end
      
      vout = cell(1,length(type.indizes));
      for k=1:length(type.indizes)
        v = self.storage(type.indizes{k});
        v = reshape(v,s);
        vout{k} = v;
      end
      if length(vout)==1
        vout = vout{1};
      else
        vout = cell2mat(vout);
      end
    end
  end
end

