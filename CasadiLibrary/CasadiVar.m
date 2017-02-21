classdef CasadiVar < casadi.SX
  methods ( Static )
    function c = norm(a)
      c = norm_2(a);
    end
  end
  methods
    function self = CasadiVar(name,size)
      mxSym = casadi.SX.sym(name,size);
      self = self@casadi.SX(mxSym);
    end
  end
end