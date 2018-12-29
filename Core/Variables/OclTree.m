classdef OclTree < OclStructure
  % OCLTREE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    positions
  end

  methods
    function self = OclTree(structure,p)
      % OclTree()
      if nargin == 0
        self.children = struct;
        self.positions = zeros(1,0);
      else
        self.children = struct;
        self.positions = p;
      end
    end

    function add(self,id,in2,varargin)
      % add(id,size)
      % add(id,obj)
      % add(id,obj,positions)
      if isnumeric(in2)
        % args:(id,size)
        self.addObject(id,OclMatrix(in2),varargin{:});
      else
        % args:(id,obj)
        self.addObject(id,in2,varargin{:});
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
    
    function addObject(self,id,obj,positions)
      % addVar(id, obj)
      %   Adds a structure object
      
      if nargin ==4
        self.positions=sort([self.positions,positions]);
        if isfield(self.children,id)
          self.children.(id).add(positions);
        else  
          self.children.(id) = OclTrajectory(obj,{positions});
        end
        return
      end

      objLength = prod(obj.size);
      if isfield(self.children, id)
        pos = self.positions(end)+1:self.positions(end)+objLength;
        self.positions = [self.positions,pos];
        self.children.(id).add(pos);
      elseif isempty(fieldnames(self.children)) && isempty(self.positions)
        pos = 1:objLength;
        self.children.(id) = OclTrajectory(obj,{pos});
        self.positions = pos;
      else
        pos = self.positions(end)+1:self.positions(end)+objLength;
        self.positions = [self.positions,pos];
        self.children.(id) = OclTrajectory(obj,{pos});
      end
    end
    
    function s = size(self)
      % s= size()
      %   Returns the size of the structure
      %   The size is determined by the leave structure
      s = size(self.positions);
    end
    
    function r = get(self,id)
      % get(id)

      c = self.children.(id);
      pArray = OclTree.merge(self.positions,c.positionArray);
      if length(pArray) == 1
        r = OclMatrix('p',pArray{1});
      else
        r = OclTrajectory(c,pArray);
      end
    end

    function tree = getFlat(self)
      tree = OclTree();
      self.iterateLeafs(self.positions(),tree);
    end
    
    function iterateLeafs(self,positions,treeOut)
      childrenIds = fieldnames(self.children);
      for m=1:length(childrenIds)
        % get children
        id = childrenIds{m};
        child = self.children.(id);
        if isa(child,'OclMatrix')
          pos = OclStructure.merge(positions,child.positions);
          treeOut.add(id,child,pos);
        elseif isa(child,'OclTree')
          pos = OclStructure.merge(positions,child.positions);
          child.iterateLeafs(id,pos,treeOut);
        elseif isa(child,'OclTrajectory')
          for i=1:length(child.positionArray)
            childType = child.type();
            childPositions = child.positionArray{i};
            pos = OclStructure.merge(positions,childPositions);
            if isa(child.type(),'OclMatrix')
              treeOut.add(id,child,pos);
            elseif isa(child.type(),'OclTree')
              childType.iterateLeafs(pos,treeOut);
            else
              oclError("Children of a trajectory can not be a trajectory");
            end
          end
        end
      end
    end % iterateLeafs
  end % methods
end % class



