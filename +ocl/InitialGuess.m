classdef InitialGuess < handle

  properties
    data
  end

  methods

    function self = InitialGuess()
      
    end
    
    function add(self, name, xdata, ydata)
      self.data.(name).x = xdata;
      self.data.(name).y = ydata;
    end

  end

end
