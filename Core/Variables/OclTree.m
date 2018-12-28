classdef OclTree < VarStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  
  properties (Access = public)
    
    % thisPositions from VarStructure
    % thisSize inherited from VarStructure
    id
    childPointers
    thisLength
    
  end

  methods
    function self = OclTree(in,positions)
      % OclTree(id)
      % OclTree(node,positions)
      
      if ischar(in)
        % id
        self.id = in;
        self.thisSize = [0 1];
        self.childPointers = struct;
        self.thisLength = 0;
        self.thisPositions = {};
      else
        self.id = in.id;
        self.thisSize = in.thisSize;
        self.childPointers = in.childPointers;
        self.thisLength = in.thisLength;
        self.thisPositions = positions;
      end
    end
    
    function r = positions(self)
      r = self.thisPositions;
    end

    function add(self,varargin)
      % add(id,size)
      %   Add a new variable from id and size
      % add(structure)
      %   Add a copy of the given variable
      narginchk(2,3);
      if nargin == 3
        % args:(id,size)
        idIn = varargin{1};
        sizeIn = varargin{2};
        self.addMatrix(idIn,sizeIn);
      elseif nargin == 2
        % args:(var)
        structureIn = varargin{1};
        self.addVar(structureIn);
      end
    end % add
    
    function addRepeated(self,structureArray,N)
      % addRepeated(self,structureArray,N)
      %   Adds repeatedly a list of structures
      %     e.g. ocpVar.addRepeated([stateStructure,controlStructure],20);
      for i=1:N
        for j=1:length(structureArray)
          self.add(structureArray{j})
        end
      end
    end
    
    function addVar(self,varIn)
      % addVar(var)
      %   Adds a reference of the varStructure
      
      if isempty(varIn)
        return
      end
            
      varLength = prod(varIn.size);
      positions = self.thisLength+1:self.thisLength+varLength;
      
      if isfield(self.childPointers,varIn.id)
        self.childPointers.(varIn.id).positions = [self.childPointers.(varIn.id).positions,{positions}]; 
      else
        self.childPointers.(varIn.id).node = varIn; 
        self.childPointers.(varIn.id).positions = {positions};
      end
      
      self.thisLength = self.thisLength+varLength;
      self.thisPositions = {1:self.thisLength};
    end
    
    function addMatrix(self,id,size)
      % Adds a Matrix as Leave of tree
      varLength = prod(size);
      positions = self.thisLength+1:self.thisLength+varLength;
      
      if isfield(self.childPointers,id)
        self.childPointers.(id).positions = [self.childPointers.(id).positions,{positions}]; 
      else
        self.childPointers.(id).node = MatrixStructure(size); 
        self.childPointers.(id).positions = {positions};
      end
      
      self.thisLength = self.thisLength+varLength;
      self.thisPositions = {1:self.thisLength};
    end
    
    function s = size(self,varargin)
      % size
      %   Returns the size of the structure
      %   The size is determined by the leave structure
      if isempty(fieldnames(self.childPointers))
        if nargin > 1
          s = self.thisSize(varargin{1});
        else
          s = self.thisSize;
        end
      else
        s = [self.thisLength 1];
      end
    end
    
    function r = get(self,in1,varargin)
      % get(id)
      % get(id,selector)
      % get(selector)
      if ischar(in1) && (~strcmp(in1,'end'))
        parentPositions = self.positions();
        r = self.getWithPositions(in1,parentPositions,varargin{:});
      else
        % get(selector)
        pos = self.positions();
        pos = pos{1};
        if strcmp(in1,'end')
          in1 = length(pos);
        end
        assert(isnumeric(in1) && nargin == 2, 'OclTree.get: Wrong arguments given.')
        r = MatrixStructure(size(in1), {pos(in1)});
      end
    end
    
    function r = getWithPositions(self,id,parentPositions,selector)
      assert(ischar(id))
      if ~isfield(self.childPointers,id)
        error('OclTree.get: Can not obtain id from this variable.');
      end
      
      if nargin < 4
        selector = ':';
      end
      
      if strcmp(selector,'all')
        selector = ':';
      end
      
      % get children
      child = self.childPointers.(id);
      
      % access children by index
      if strcmp(selector,'end')
        child.positions = child.positions(end);
      else
        if isa(child.node,'OclMatrix')
          for i=1:length(child.positions)
            childPos = child.positions{i};
            child.positions{i} = childPos(selector);
          end
        else
          child.positions = child.positions(selector);
        end
      end
      
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
      
      if length(positions) == 1 && isa(child.node,'OclTree')
        r = TreeNode(child.node,positions);
      elseif length(positions)==1 && isa(nodeType,'OclMatrix') 
        r = MatrixStructure(nodeType.size,positions);
      else
        r = Trajectory(child.node,positions);
      end
    end % getWithPositions
    
    function tree = getFlat(self)
      parentPositions = self.positions();
      tree = TreeNode(self.id);
      tree.thisLength = self.thisLength;
      tree.thisPositions = parentPositions;
      self.iterateLeafs(parentPositions,tree);
    end
    
    function iterateLeafs(self,parentPositions,treeOut)
      
      childsFields = fieldnames(self.childPointers);

      for m=1:length(childsFields)
        % get children
        child = self.childPointers.(childsFields{m});

        % access children by index
        child.positions = child.positions;

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
        
        if isa(child.node,'OclMatrix')
          
          this = child.node;
          thisID = childsFields{m};
        
          if isfield(treeOut.childPointers,thisID)

            % combine, sort positions
            oldPositions = treeOut.childPointers.(thisID).positions;
            newPositions = sort([oldPositions{:},positions{:}]);

            % split positions to cell
            cellLength = prod(this.size);
            cellN      = length(newPositions)/cellLength;         

            pCell = cell(1,cellN);
            for k=1:cellN
              pCell{k} = newPositions(cellLength*(k-1)+1:cellLength*k);
            end
            treeOut.childPointers.(thisID).positions = pCell;

          else
            treeOut.childPointers.(thisID) = struct;
            treeOut.childPointers.(thisID).node = this;
            treeOut.childPointers.(thisID).positions = positions;
          end
        
        else
          child.node.iterateLeafs(positions,treeOut);
        end
      end
    end % iterateLeafs
    
    function r = getChildPointers(self)
      r = self.childPointers;
    end
  end % methods
end % class



