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
        subVar = self.subVars{i};
        if isa(subVar,'Var')
          subVar.compile;
        end
      end

      N = length(self.subVars);
      if N == 0
        nv = 0;
      else
        nv = prod(self.subVars{1}.size);
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
        nv = prod(self.subVars{1}.size);
        N = length(self.subVars);
        s = [nv,N];
      end
    end
    
    function v = value(self)
      % value
      % Returns the values of the variable
      
      % Return value of the Var based on the subVars, if any, otherwise assigned value.

      % stack the variables recursively
      N_SubVars = length(self.subVars);
      N_SubVarElements = prod(self.subVars{1}.size);
      v = zeros(N_SubVarElements,N_SubVars);
      for i=1:length(self.subVars)
        subVar = self.subVars{i};
        v(:,i) = subVar.flat;
      end

    end
    
    function var = get(self,id,varargin)
      % get(id)
      % get(id,slice)
      
      if ~isfield(self.varIds,id) && self.varIds.size ~= 1
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
      indizes = self.subVars{1}.varIds.(id);
      indizes = indizes(sliceOp);
      for i = 1:length(self.subVars)
        subVar = self.subVars{i}.subVars{indizes};
        var.addVar(subVar);
      end        
      
      % if exactly one match, return the single matching Var
      if length(var.subVars) == 1
        var = var.subVars{1};
        return;
      end
      var.compile;
      
    end % get
    
    function set(self,valueIn)
      % set(value)
      
      % assign scalar value to all variables
      if numel(valueIn)==1
        valueIn = valueIn * ones(size(self));
      end
      
      % assign value if there are no subVars
      if isempty(self.subVars)
        self.assignValue(valueIn);
        return
      end
      
      if isequal(self.size,size(valueIn)) || isequal( prod(self.size), prod(size(valueIn)) )
        % assign value to subvars
        self.setSplitToAll(valueIn);
      elseif isequal(numel(valueIn),prod(self.subVars{1}.size))
        % assign same value to all subvars 
        for i = 1:length(self.subVars) 
          subVar = self.subVars{i};
          subVar.set(valueIn);
        end
      else
        error('Error: Can not assign value to variable.');
      end
        
    end % set
    
  end
  
end

