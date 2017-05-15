classdef SubVar < VarBase
  %SUBEXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    parent
    positions
  end
  
  methods
    
    function self = SubVar(treeVar,parent,positions)
      self = self@VarBase(treeVar);
      self.parent     = parent;
      self.positions  = positions;
    end
    
    function set(self,valueIn,slices)
      % set(self,valueIn,slicesIn)
      
      if nargin == 2
        slices = self.mergeSlices();
      else
        slices = self.mergeSlices(slices);
      end

      self.parent.set(valueIn,slices);
      
    end
    
    function v = value(self,slices,var)
      % value(self,slicesIn,varIn)
      
      if nargin == 1
        var = self;
        slices = self.mergeSlices();
      else
        slices = self.mergeSlices(slices);
      end
      
      v = self.parent.value(slices,var);
    end
    
%     function s = size(self,slices)
%       if nargin == 1
%         slices = self.mergeSlices();
%       else
%         slices = self.mergeSlices(slices);
%       end
%       s = self.parent.size(slices);
%     end
    
  end
  
  methods (Access = private)
    
    function slices = mergeSlices(self,slicesIn)
      % slices = mergeSlices(self,slicesIn)
      
      varLength = prod(self.treeVar.size);
      if nargin == 1
        slicesIn = {1:varLength};
      end
            
      NPositions = length(self.positions);
      
      slices = cell(1,NPositions*length(slicesIn));
      i = 1;
      for k=1:NPositions
        pos = self.positions(k);
        slice = pos:pos+varLength-1;
        
        for l=1:length(slicesIn)
          slices{i} = slice(slicesIn{l});
        end
        i = i+1;
      end
      
    end
    
  end
  
end

