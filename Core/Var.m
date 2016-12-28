classdef Var < matlab.mixin.Copyable
  %Var Variable class
  %   Basic datatype to store structured variables.
  %   Deriving of Copyable provides copy() method.
  
  properties (Access = public)
    id
    subVars
    thisValue
    thisSize
    
    compiled
    varIds
  end

  methods
    function self = Var(varargin)
      % Var(id)
      % Var(id,size)
      % Var(value,id)
      % Var(var)
      
      
      
      narginchk(0,2);
      self.clear
      
      % if no arguments give, return empty var
      % should only be used by subclasses
      if nargin == 0
        return
      end

      if isa(varargin{1},'Var')
        % copy recursively from given var
        self            = varargin{1}.copy;

      elseif ischar(varargin{1}) 
        % create a new variable from id and size
        self.id         = varargin{1};
        if nargin == 2
          self.thisSize = varargin{2};
          self.compiled = true;
        end

      elseif nargin == 2 && ischar(varargin{2})
        % create a new variable from value and id
        self.id         = varargin{2};
        self.thisSize   = size(varargin{1});
        self.set(varargin{1});
        self.compiled = true;
      else
        error('Error in the argument list.');
      end
    end % Var constructor
    
    function clear(self)
      self.subVars = {};
      self.thisValue = [];
      self.thisSize = [0 1];
      self.varIds = java.util.HashMap;
      self.compiled = false;
    end
    
        
    function compile(self)
      
      if self.compiled
        return
      end
      
      for i=1:length(self.subVars)
        subVar = self.subVars(i);
        subVar.compile;
        
        if isempty(self.thisSize)
          self.thisSize = [0 1];
        end
        self.thisSize(1) = self.thisSize(1) + prod(subVar.size);
      end
      self.compiled = true;
    end
    
    function add(self,varargin)
      % add(id,size)
      %   Add a new variable from id and size
      % add(var)
      %   Add a copy of the given variable
      
      % parse inputs
      narginchk(2,3);
      if nargin == 3
        % create new Var from id and size
        idIn = varargin{1};
        sizeIn = varargin{2};
        varIn = Var(idIn,sizeIn);
      elseif nargin == 2
        varIn = varargin{1}.copy;
      end

      if ~isempty(varIn.size) && ~(prod(varIn.size) == 0)
        self.addVar(varIn)
      end
    end % add
    
    function addRepeated(self,varArray,N)
      % addRepeated(self,varArray,N)
      %   Adds repeatedly a list of variables
      %     e.g. ocpVar.addRepeated([stateVar,controlVar],20);
      for i=1:N
        for j=1:length(varArray)
          self.add(varArray(j))
        end
      end
    end % addRepeated
    
    function addVar(self,varIn)
      % addVar(var)
      %   Adds a reference of the var
      
      if ~varIn.compiled
        error('Only compiled vars can be added.');
      end
      
      if self.compiled
        error('Can not add variables to a compiled var.');
      end
      
      
      self.subVars = [self.subVars,varIn];
      
      thisIndex = length(self.subVars);
      
      indizes = [self.varIds.get(varIn.id);thisIndex];
      self.varIds.put(varIn.id,indizes);
      
      for i = 1:length(varIn.varIds.keySet.toArray.cell)
        key = varIn.varIds.keySet.toArray.cell{i};
        indizes = [self.varIds.get(key);thisIndex];
        self.varIds.put(key,indizes);
      end
    end
    
    function s = getNumberOfVars(self)
      s = length(self.subVars);
    end
    
    function s = size(self)
      % size
      %   Returns the size of the variable
      %   The size is determined by the leave variables
      
      if self.compiled
        s = self.thisSize;
        return
      end
      
      % Return size of the Var based on the subVars, if any, otherwise assigned size.
      if ~isempty(self.subVars) 
        % sum up the sizes of subVars
        s = 0;
        for i=1:length(self.subVars)
          subVar = self.subVars(i);
          if ~isempty(subVar.size)
            s = s + prod(subVar.size);
          end
        end
        s = [s 1];
      else
        s = self.thisSize;
      end
    end
    
    function v = value(self)
      % value
      % Returns the values of the variable
      
      % Return value of the Var based on the subVars, if any, otherwise assigned value.
      if ~isempty(self.subVars) 
        
        % if all subvars have the same id and size, make matrix, otherwise
        % a column vector
        
        % check for size and id, stop if any of the two dont match
        stackAsMatrix = true;
        subVarId = self.subVars(1).id;
        subVarSize = self.subVars(1).size;
        for i = 2:length(self.subVars)
          subVar = self.subVars(i);
          if ~strcmp(subVar.id,subVarId) || ~isequal(subVar.size,subVarSize)
            stackAsMatrix = false;
            break
          end
        end
        
        % stack the variables recursively
        v = [];
        for i=1:length(self.subVars)
          subVar = self.subVars(i);
          if stackAsMatrix
            v = [v, subVar.flat];
          else
            v = [v; subVar.flat];
          end
        end
        
      else
        if isempty(self.thisValue)
          v = [];
        else
          v = reshape(self.thisValue, self.thisSize);
        end
      end
    end
    
    function v = flat(self)
      % Returns a flat representation of the variable (columns vector)
      
      % Return value of the Var based on the subVars, if any, otherwise assigned value.
      if ~isempty(self.subVars) 
        % sum up the sizes of subVars
        v = [];
        for i=1:length(self.subVars)
          subVar = self.subVars(i);
          v = [v; subVar.flat];
        end
      else
        v = self.thisValue';
      end      
    end % flat
    
    
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
      

      var = Var(newVarId);
      
      
      % check if all subvars have the same id which is not the designated id
      % get all subvars
%       if self.varIds.size == 1 && ~self.varIds.containsKey(id)
      if ~strcmp(self.subVars(1).id,id) && all(strcmp({self.subVars.id},self.subVars(1).id))
        for i=1:length(self.subVars)
          subVar = self.subVars(i).get(id,sliceOp);
          var.addVar(subVar);
        end
        
      end
      
      % get child vars with id
      % 
      indizes = self.varIds.get(id);
      counter = 0;
      slice = sliceOp;
      for i = indizes'
        subVar = self.subVars(i);
        
        if strcmp(subVar.id,id)
          counter = counter+1;
        
          if strcmp(slice,':')
            var.addVar(subVar);
          elseif counter == slice(1)
            slice = slice(2:end);
            var.addVar(subVar);
          end
        end
        
        if isempty(slice)
          break
        end
        
      end
      
      % if exactly one match, return the single matching Var
      if length(var.subVars) == 1
        var = var.subVars(1);
        return;
      end
      
      var.compile;
      
    end % get
    
    

    function var = getDeep(self,id,varargin)
      % get(id)
      % get(id,slice)
      
      if ~self.varIds.containsKey(id)
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
      

      % get child vars recursively
      % 
      indizes = self.varIds.get(id);
      var = Var(newVarId);
      counter = 0;
      slice = sliceOp;
      for i = indizes'
        subVar = self.subVars(i);
        [var,counter,slice] = subVar.getSubVar(var,id,counter,slice);
        if isempty(slice)
          break
        end
      end
      
      % if exactly one match, return the single matching Var
      if length(var.subVars) == 1
        var = var.subVars(1);
        return;
      end
      
    end % get
    
    
    function [var,counter,slice] = getSubVar(self,var,id,counter,slice)
      % This function is private and used by the get method
      
      if isempty(slice)
        return
      end
      
      if strcmp(self.id,id)
        counter = counter+1;
        if strcmp(slice,':')
          var.addVar(self);
        elseif counter == slice(1)
          slice = slice(2:end);
          var.addVar(self);
        end
        return
      end
   
      % get indizes of subVars with given id
      indizes = self.varIds.get(id)';
      
      for i = indizes
        subVar = self.subVars(i);
        [var,counter,slice] = subVar.getSubVar(var,id,counter,slice);
      end
      
    end

    
    function set(self,valueIn)
      % set(value)
      
      if numel(valueIn)==1 && prod(size(self))~=1
        % assign scalar value to all variables
        valueIn = valueIn * ones(size(self));
      end
      
      
      % assign value if there are no subVars
      if isempty(self.subVars)
        
        if isempty(self.size) || numel(valueIn) ==0
          % nothing to assign
          return;
        end
        
        if ~isequal(prod(self.size),numel(valueIn))
          % number of element don't match, cant assign
          warning('Size of var and size of value (number of elements) dont match, ignoring.');
          return
        end
        
        % assign value
        self.thisValue = reshape(valueIn,1,prod(self.size));
        return
        
      end
      
      % assign value to subvars
      if isequal(self.size,size(valueIn))
        % Split value to subvars if size of value corresponds to size of variable

      	% split value to subvars
        index = 1;
        for i = 1:length(self.subVars)
          subVar = self.subVars(i);
          subVar.set(valueIn(index:index+prod(subVar.size)-1));
          index = index + prod(subVar.size);
        end 
      
      else
        % assign same value to all subvars if sizes match
        
        % check if all subvars have the same id and size
        subVarId = self.subVars(1).id;
        subVarSize = self.subVars(1).size;
        for i = 2:length(self.subVars)
          subVar = self.subVars(i);
          if ~strcmp(subVar.id,subVarId) || ~isequal(subVar.size,subVarSize)
            warning('All Variables have to have the same id and size, doing nothing.');
            return
          end
        end
        for i = 1:length(self.subVars) 
          subVar = self.subVars(i);
          subVar.set(valueIn);
        end
      end
    end % set
    
    
    function printStructure(self, varargin)
      
      level = 0;
      prefix = '';
      if nargin == 4
        level = varargin{1};
        prefix = varargin{2};
        index = varargin{3};
        
        delimiter = '';
        if ~strcmp(prefix,'')
          delimiter = '_';
        end
        prefix = [prefix delimiter self.id index];
      end
      
      fprintf('%s%s\n', repmat('-', 1,4*level), prefix);
      
      level = level+1;
      
      for i = 1:length(self.subVars)
        
        subVar = self.subVars(i);
        indizes = self.varIds.get(subVar.id);
        
        % find i in indizes
        subIndex = num2str(find(indizes==i));
        if length(indizes)==1
          subIndex = '';
        end
        subVar.printStructure(level,prefix,subIndex);
      end
    end

    function setLinear(self,startValue,endValue)
      N = prod(self.size);
      values = linspace(startValue,endValue,N)';
      self.set(values); 
    end
    
  end % methods

  methods(Access = protected)
    function cpObj  = copyElement(self)
      % override copyElement to return a Var with deep copy of subVars 
      % when calling copy()
      cpObj = copyElement@matlab.mixin.Copyable(self);
      if ~isempty(cpObj.subVars)
        cpObj.subVars = copy(self.subVars);
      end
    end
  end % protected methods
  
end % class



