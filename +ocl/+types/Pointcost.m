classdef Pointcost < handle

  properties
    point
    fh
  end
  
  methods
  
    function self = Pointcost(point, fh)
      self.point = point;
      self.fh = fh;
    end
    
  end
  
end