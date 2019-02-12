classdef OclTensorChild < handle
  
  properties
    tensor
    indizes
    shapes
  end
  
  methods
    
    function self = OclTensorChild(t,p,shapes)
      self.tensor = t;
      self.indizes = p;
      self.shapes = shapes;
    end
    
    function r = get(self, id)
      r = self.tensor.get(id, self.indizes,self.shapes);
    end
    
    function r = type(self)
      r = self.tensor.type();
    end
    
    function r = children(self)
      r = self.tensor.children;
    end
    
  end
end