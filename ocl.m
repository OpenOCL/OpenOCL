classdef ocl < handle
  methods (Static = true)
      function val = setupCompleted(newval)
          persistent currentval;
          if nargin >= 1
              currentval = newval;
          end
          val = currentval;
      end
  end
  
  methods
    function self = ocl()
      if isempty(ocl.setupCompleted) || ~ocl.setupCompleted
        StartupOCL
        ocl.setupCompleted(true);
      end
    end
  end
end