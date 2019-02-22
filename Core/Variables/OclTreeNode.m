classdef OclTensorRoot < handle
  
  properties
    structure
    indizes
    shapes
  end
  
  methods
    
    function self = OclTensorRoot(structure,indizes,shapes)
      self.structure = structure;
      self.indizes = indizes;
      self.shapes = shapes;
    end
    
    function r = shape(self)
      r = [self.shapes length(self.indizes)];
    end
    
    function r = get(self, id)
      r = self.structure.get(id,self.indizes,self.shapes(2:end));
    end
    
    function r = type(self)
      r = self.structure.type();
    end
    
    function r = children(self)
      if isempty(self.structure)
        r = struct;
      else
        r = self.structure.children;
      end
    end
    
  end
end