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
    
    function r = elements(self)
      r = self.elements_p;
    end
    
    function add(self, id, dimensions, subvars)
      
      elements = self.elements_p;
      len = self.len_p;
      
      N = prod(dimensions);
      
      if nargin == 3
        subvars = cell(1,N);
        for k=1:N
          subvars{k} = [id, num2str(k)];
        end
      end
      
      ocl.utils.assertEqual(length(subvars), N, ...
        'Must specify names for each element.');
      
      ocl.utils.assert( ...
        ~ocl.utils.fieldnamesContain(fieldnames(elements), id), ...
        'Name already exists.');
      
      elements.(id) = struct;
      elements.(id).positions = len+1:len+N;
      elements.(id).dimensions = dimensions;
      
      % insert sub-names
      for k=1:N
        ocl.utils.assert( ...
          ~ocl.utils.fieldnamesContain(fieldnames(elements), subvars{k}), ...
          'Name already exists.');
        elements.(subvars{k}) = struct;
        elements.(subvars{k}).positions = len+k;
        elements.(subvars{k}).dimensions = dimensions;
        elements.(subvars{k}).children = {};
      end
      
      self.len_p = len + N;
      self.elements_p = elements;
    end
    
    function [t,p] = get(self, id)
      
    end
    
  end
end