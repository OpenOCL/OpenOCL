classdef TestExternalFunction < CasadiExternalFunction
  
  methods
    function f = setupFunction(self,x)

      f = x(1)*x(2);

    end
  end
  
end