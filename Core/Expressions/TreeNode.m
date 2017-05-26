classdef TreeNode < VarStructure
  %VarStructure
  %   Basic datatype represent variables in a tree like structure.
  
  
  properties (Access = public)
    
    % thisSize inherited from VarStructure
    id
    childPointers
    thisLength
    
  end

  methods
    function self = TreeNode(varargin)
      % VarStructure(id)
      % VarStructure(id,size)
      % VarStructure(var)
      % VarStructure()

      narginchk(0,2);
      self.clear
      
      
      % if no arguments give, return empty var
      % should only be used by subclasses
      if nargin == 0
        return
      end

      if isa(varargin{1},'TreeNode')
        % copy recursively from given var
        self            = varargin{1};

      elseif ischar(varargin{1}) 
        % create a new variable from id and size
        self.id         = varargin{1};
        if nargin > 1 && isa(varargin{2},'double')
          self.thisSize = varargin{2};
          self.thisLength = prod(self.thisSize);
        end
      else
        error('Error in the argument list.');
      end
    end % VarStructure constructor
    
    function clear(self)
      self.thisSize = [0 1];
      self.childPointers = struct;
      self.thisLength = 0;
    end
    
    function r = positions(self)
      r = {1:self.thisLength};
    end

    function add(self,varargin)
      % add(id,size)
      %   Add a new variable from id and size
      % add(var)
      %   Add a copy of the given variable
      
      % parse inputs
      narginchk(2,3);
      if nargin == 3
        % create new VarStructure from id and size
        idIn = varargin{1};
        sizeIn = varargin{2};
        varIn = TreeNode(idIn,sizeIn);
      elseif nargin == 2
        varIn = varargin{1};
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
      
      varLength = prod(varIn.size);
      positions = self.thisLength+1:self.thisLength+varLength;
      
      if isfield(self.childPointers,varIn.id)
        % TODO check that sizes match
        self.childPointers.(varIn.id).positions = [self.childPointers.(varIn.id).positions,positions]; 
      else
        self.childPointers.(varIn.id).node = varIn; 
        self.childPointers.(varIn.id).positions = {positions};
      end
      
      self.thisLength = self.thisLength+varLength;
      
    end
    
    function s = size(self)
      % size
      %   Returns the size of the variable
      %   The size is determined by the leave variables
      
      if isempty(fieldnames(self.childPointers))
        s = self.thisSize;
      else
        s = [self.thisLength 1];
      end
      
    end
    
    function subVar = get(self,id,varargin)
      % get(id)
      % get(id,selector)
      
      parentPositions = {1:self.thisLength};
      subVar = self.getWithPositions(id,parentPositions,varargin{:});
      
      
    end % get    
    
    function subVar = getWithPositions(self,id,parentPositions,selector)
      
      if ~isfield(self.childPointers,id)
        error('Error: Can not obtain id from this variable.');
      end
      
      if nargin < 4
        selector = ':';
      end
      
      % get children
      child = self.childPointers.(id);
      
      % access children by index
      child.positions = child.positions(selector);
      
      % get merge all parent and child positions
      Nchilds = length(child.positions);
      
      positions = cell(1,Nchilds*length(parentPositions));
      i = 1;
      for l=1:length(parentPositions)
        thisParentPos = parentPositions{l};
        for k=1:Nchilds
          pos = child.positions{k};
          positions{i} = thisParentPos(pos);
          i = i+1;
        end
      end    
      
      subVar = NodeSelection(child.node,positions);
    end
    
  end % methods
  
end % class



