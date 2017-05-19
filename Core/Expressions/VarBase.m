classdef VarBase < Arithmetic
  %EXPRESSIONBASE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    treeVar
  end
  
  methods
    set(self)
    value(self)
  end
  
  methods
    
    function self = VarBase(treeVar)
      self.treeVar = treeVar;
    end
    
    function e = get(self,id,varargin)
      narginchk(2,3);
      [subVar,indizes] = self.treeVar.get(id,varargin{:});
      sizes = self.treeVar.getSizes();
      
      positions = [];
      
      pos = 1;
      for k=1:length(sizes)
        
        if k == indizes(1)
          positions = [positions,pos];
          indizes(1) = [];
          if isempty(indizes)
            break
          end
        end

        pos = pos + prod(sizes{k});
      end
      
      e = SubVar(subVar,self,positions);
    end
    
    function s = size(self)
      s = self.treeVar.size;
    end
    
  end
  
end

