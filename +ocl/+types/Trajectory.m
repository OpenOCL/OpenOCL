classdef Trajectory < handle
  
  properties 
    structure_p
    gridpoints_p
    data_p
  end
  
  methods
    
    function self = Trajectory(structure, gridpoints, data)
      self.structure_p = structure;
      self.gridpoints_p = gridpoints;
      self.data_p = data;
    end
    
    function get(self, id)
      
    end
    
    function at(self, gridpoint)
      
    end
    
    function gridpoints(self)
      
    end
    
  end
  
end