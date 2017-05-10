classdef UniformVar < Var
  
  properties
    childSize
    childId
  end
  
  methods
    
    function self = UniformVar(varargin)
      self = self@Var(varargin{:});
    end
    
    function compile(self)

      if self.compiled
        return
      end
      
      % compile all subVars
      for i=1:length(self.subVars)
        subVar = self.subVars(i);
        subVar.compile;
      end

      N = length(self.subVars);
      if N == 0
        nv = 0;
      else
        nv = prod(self.subVars(1).size);
      end
      self.thisSize = [nv,N];

      self.compiled = true;
    end
    
    function s = size(self)
      % size
      %   Returns the size of the variable
      %   The size is determined by the leave variables
      
      if self.compiled || isempty(self.subVars) 
        s = self.thisSize;
      else
        % Return size of the Var based on the subVars
        nv = prod(self.subVars(1).size);
        N = length(self.subVars);
        s = [nv,N];
      end
    end
    
    function v = value(self)
      % value
      % Returns the values of the variable
      
      % Return value of the Var based on the subVars, if any, otherwise assigned value.
      if ~isempty(self.subVars) 
        
        % if all subvars have the same id and size, make matrix, otherwise
        % a column vector
        
        % stack the variables recursively
        v = [];
        for i=1:length(self.subVars)
          subVar = self.subVars(i);
          v = [v, subVar.flat];
        end
      else
        if isempty(self.thisValue)
          v = [];
        else
          v = reshape(self.thisValue, self.thisSize);
        end
      end
    end
    
    function var = get(self,id,varargin)
      % get(id)
      % get(id,slice)
      
      if ~self.varIds.containsKey(id) && self.varIds.size ~= 1
        var = Var([self.id '_' id '_empty']);
        warning('Did not find id in variable.');
        return;
      end

      narginchk(2,3);
      sliceOp = ':';
      if nargin == 3
        sliceOp = varargin{1};
      end
      
      % create new Var containing all matching subVars, and indicate slice
      % in the variables name
      newVarId = [self.id '_' id];
      if ~strcmp(sliceOp,':')
        newVarId = [self.id '_' num2str(sliceOp(1)) ':' num2str(sliceOp(end))];
      end
      

      var = UniformVar(newVarId);
      
      
      % get subvars 
      subIndizes = self.subVars(1).varIds.get(id);

      for i=1:length(self.subVars)
        subVar = self.subVars(i).subVars(subIndizes);

        if strcmp(sliceOp,':')
          var.addVar(subVar);
        else
          val = subVar.value;
          newVar = Var(val(sliceOp),id);
          var.addVar(newVar);
        end

      end
        
      
      % if exactly one match, return the single matching Var
      if length(var.subVars) == 1
        var = var.subVars(1);
        return;
      end
      var.compile;
      
    end % get
    
    function slice(self)
      
    end
    
  end
  
end

