classdef Struct < handle
  
  properties
    len_p
    elements_p
  end
  
  
  methods
    
    function self = Struct()
      self.len_p = 0;
      self.elements_p = struct;
    end
    
    function r = numel(self)
      r = self.len_p;
    end
    
    function r = length(self)
      r = self.len_p;
    end
    
    function add(self, id, s, names)
      
      elements = self.elements_p;
      
      N = prod(s);
      
      if nargin == 3
        names = cell(1,N);
        for k=1:N
          names{k} = [id, num2str(k)];
        end
      end
      
      ocl.utils.assertEqual(length(names), N, ...
        'Must specify names for each element.');
      
      ocl.utils.assert( ...
        ~ocl.utils.fieldnamesContain(fieldnames(elements), id), ...
        'Name already exists.');
      elements.(id) = self.len_p+1:self.len_p+N;
      
      % insert sub-names
      for k=1:N
        ocl.utils.assert( ...
          ~ocl.utils.fieldnamesContain(fieldnames(elements), names{k}), ...
          'Name already exists.');
        elements.(names{k}) = self.len_p+k;
      end
      
      self.len_p = self.len_p + N;
      self.elements_p = elements;
      
    end
    
  end
end