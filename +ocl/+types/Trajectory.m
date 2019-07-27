classdef Trajectory < handle
  
  properties 
    points_data_p
    values_data_p
  end
  
  methods
    
    function self = Trajectory()
      self.points_data_p = [];
      self.values_data_p = [];
    end
    
    function set(self, points, values)
      
      assertEqual(numel(points), size(values,2), ...
        'The number of columns in values must match the number of given points.');
      
      points_data = self.points_data_p;
      values_data = self.values_data_p;
      
      if isempty(points_data)
        % sort data
        [sorted_points, sort_indizes] = sort(points);
        sorted_values = values(:, sort_indizes);   
      else
        % combine data and sort by points
        merged_points = [points_data, points];
        [sorted_points, sort_indizes] = sort(merged_points);
        
        merged_values = [values_data, values];
        sorted_values = merged_values(:, sort_indizes);
      end
      
      self.points_data_p = sorted_points;
      self.values_data_p = sorted_values;
    end
    
    function get(self, id)
      
    end
    
    function at(self, gridpoint)
      
    end
    
    function gridpoints(self)
      
    end
    
  end
  
end