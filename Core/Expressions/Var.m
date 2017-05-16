classdef Var < VarBase
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    thisValue
  end
  
  methods
    
    function self = Var(treeVar,value)
      self = self@VarBase(treeVar);
      self.set(value);
    end
    
    function c = copy(self)
      c = Var(self.treeVar,self.value);
    end
    
    function set(self,valueIn,sliceIn)

      if nargin == 2
        
        if isscalar(valueIn)
          valueIn = valueIn * ones(prod(self.size),1);
        end
        
        % directly assign
        if iscolumn(valueIn)
          self.thisValue = valueIn;
        elseif isrow(valueIn)
          self.thisValue = valueIn';
        elseif isempty(valueIn)
          self.thisValue = [];
        else
          error('Can not assign matrix valued value to this variable.');
        end
      else
        % Assign parts of variables given by slices
        
        if numel(sliceIn{1}) == numel(valueIn)
          % assign same value repeatetly to each slice
          for k=1:length(sliceIn)
            self.thisValue(sliceIn{k}) = valueIn;
          end
          
        elseif isscalar(valueIn)
          % assign scalar value to each element
          for k=1:length(sliceIn)
            self.thisValue(sliceIn{k}) = valueIn;
          end
          
        elseif ismatrix(valueIn) && length(sliceIn) == size(valueIn,2)
          % assign each column of value to each slice
          for k=1:length(sliceIn)
            self.thisValue(sliceIn{k}) = valueIn(:,k);
          end
          
        elseif isnumeric(valueIn) && length(sliceIn) == size(valueIn,3)
          % assign multidimensional matrix
          for k=1:length(sliceIn)
            self.thisValue(sliceIn{k}) = valueIn(:,:,k);
          end
          
        else
          error('Error: Can not assign value to variable, dimensions do not match.');
        end
        
      end
      
    end
    
    function v = value(self,sliceIn,varIn)
      
      if nargin == 1
        v = self.thisValue;
      else
        varSize = varIn.size;
        if varSize(1) ~= 1 && varSize(2) ~= 1
          
          % stack matrizes
          v = zeros(varSize(1),varSize(2),length(sliceIn));
          for k=1:length(sliceIn)
            val = reshape( self.thisValue(sliceIn{k}) , varSize );
            v(:,:,k) = val;
          end
          
        else
          % stack vectors
          v = zeros(max(varSize),length(sliceIn));
          for k=1:length(sliceIn)
            val = reshape( self.thisValue(sliceIn{k}) , varSize );
            v(:,k) = val;
          end
        end

      end
      
    end
    
  end
  
end

