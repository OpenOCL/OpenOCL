classdef Var
  
  properties
    structure_p
    value_p
    positions_p
  end
  
  
  methods
    
    function self = Var(structure, value)
      
      N = length(structure);
      
      self.structure_p = structure;
      self.value_p = value;
      self.positions_p = 1:N;
    end
    
    function r = slice(self)
      
    end
    
  end
  
end