classdef OclTree < OclStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    % positions (OclStructure)
    children
    len
  end

  methods
    function self = OclTree()
      % OclTree()
      self.children = struct;
      self.positions = struct;
      self.len = 0;
    end
    
    function r,p = get(self,id,p)
      % get(id)
      % get(id)
      r = self.children.(id);
      p = OclTree.merge(p,self.positions.(id))
    end

    function add(self,id,in2)
      % add(id,size)
      %   Add a new variable from id and size
      % add(id,obj)
      %   Add a copy of the given variable
      narginchk(2,3);
      if isnumeric(in2)
        % args:(id,size)
        self.addObject(id,OclMatrix(in2));
      else
        % args:(id,obj)
        self.addObject(id,in2);
      end
    end
    
    function addRepeated(self,arr,N)
      % addRepeated(self,arr,N)
      %   Adds repeatedly a list of structure objects
      %     e.g. ocpVar.addRepeated([stateStructure,controlStructure],20);
      for i=1:N
        for j=1:length(arr)
          self.add(arr{j})
        end
      end
    end
    
    function addObject(self,id,obj)
      % addVar(id, obj)
      %   Adds a structure object (by reference)
      
      if isempty(obj)
        warning('OclTree')
      end
      
      objLength = prod(obj.size);
      newLength = self.len+objLength;

      if isfield(self.children, id)
        self.children.(id){end+1} = obj;
        self.positions.(id){end+1} = 1:newLength;
      else
        self.children.(id) = {obj};
        self.positions.(id) = {1:newLength};
      end
      self.len = newLength;
    end
    
    function s = size(self)
      % s= size()
      %   Returns the size of the structure
      %   The size is determined by the leave structure
      ids = fieldnames(self.children);
      s = [0,1];
      for i=1:length(ids)
        thisId = ids{i}
        s(1) = s(1) + prod(self.children.(thisId).size())
      end
    end

    function tree = getFlat(self)
      parentPositions = self.positions();
      tree = OclTree(self.id);
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
  end % methods
end % class



