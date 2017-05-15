classdef Var < handle
  %Var Variable class
  %   Basic datatype to store structured variables.
  
  properties (Access = public)
    
    id
    subVars
    thisSize
    
    compiled
    varIds
  end

  methods
    function self = Var(varargin)
      % Var(id)
      % Var(id,size)
      % Var(var)
      % Var()

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
        if nargin > 1 && isa(varargin{2},'double')
          self.thisSize = varargin{2};
          self.compiled = true;
        end
      else
        error('Error in the argument list.');
      end
    end % Var constructor
    
    function clear(self)
      self.subVars = {};
      self.thisSize = [0 1];
      self.varIds = struct;
      self.compiled = false;
    end
    
    function c = copy(self)
      classType = str2func(class(self));
      c = classType();
      c.id        = self.id;
      c.thisSize  = self.thisSize;
      c.varIds    = self.varIds;
      c.compiled  = self.compiled;
      
      for k=1:length(self.subVars)
        cp = copy(self.subVars{k});
        c.subVars = builtin('horzcat',c.subVars,{cp});
      end
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

      for i=1:length(self.subVars)
        subVar = self.subVars{i};

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

      self.addVar(varIn)
    end % add
    
    function addRepeated(self,varArray,N)
      % addRepeated(self,varArray,N)
      %   Adds repeatedly a list of variables
      %     e.g. ocpVar.addRepeated([stateVar,controlVar],20);
      for i=1:N
        for j=1:length(varArray)
          self.add(varArray{j})
        end
      end
    end % addRepeated
    
    function addVar(self,varIn)
      % addVar(var)
      %   Adds a reference of the var
      
      if self.compiled
        error('Can not add variables to a compiled var.');
      end   
      
      self.subVars = builtin('horzcat',self.subVars,{varIn});
      
      thisIndex = length(self.subVars);
      
      indizes = [];
      if isfield(self.varIds,varIn.id)
        indizes = self.varIds.(varIn.id);
      end
      indizes = [indizes;thisIndex];
      
      self.varIds.(varIn.id) = indizes;
      
      if isa(varIn,'Var')
        keys = fieldnames(varIn.varIds);
        for i = 1:length(keys)
          key = keys{i};
          indizes = [];
          if isfield(self.varIds,key)
            indizes = self.varIds.(key);
          end
          self.varIds.(key) = [indizes;thisIndex];
        end
      end
      
    end
    
    function s = size(self)
      % size
      %   Returns the size of the variable
      %   The size is determined by the leave variables
      
      if self.compiled
        s = self.thisSize;
      else
        % Return size of the Var based on the subVars.
        % sum up the sizes of subVars
        s = 0;
        for i=1:length(self.subVars)
          subVar = self.subVars{i};
          if ~isempty(subVar.size)
            s = s + prod(subVar.size);
          end
        end
        s = [s 1];
      end
      
    end
    
    function [var,indizes] = get(self,id,selector)
      % get(id)
      % get(id,selector)
      
      if nargin == 2
        selector = ':';
      end
      
      if ~isfield(self.varIds,id)
        error('Error: Can not obtain id from this variable.');
      end
      
      % get child vars with id
      % 
      indizes = self.varIds.(id);
      indizes = indizes(selector);
      
      var = self.subVars{indizes(1)};
      
      if isa(var,'Var')
        var.compile;
      end
      
    end % get    
    

    
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
        
        subVar = self.subVars{i};
        indizes = self.varIds.(subVar.id);
        
        % find i in indizes
        subIndex = num2str(find(indizes==i));
        if length(indizes)==1
          subIndex = '';
        end
        subVar.printStructure(level,prefix,subIndex);
      end
    end
    
    function s = getSizes(self)
      N = length(self.subVars);
      s = cell(1,N);
      for k=1:N
        s{k} = self.subVars{k}.size;
      end
    end
    
  end % methods
  
end % class



