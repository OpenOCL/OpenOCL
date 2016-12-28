classdef CasadiExternalFunction < casadi.Callback
  methods
    function self = CasadiExternalFunction()
      self.construct('myFun');
    end 
    function init(self)
      disp('init called')
    end
    function v = eval(self, arg)
      x = arg{1};
      v = {x*x};
    end
    function n = get_n_in(self)
      n = 1;
    end
    function n = get_n_out(self)
      n = 1;
    end
    function v = get_sparsity_in(self, i)
      v = casadi.Sparsity.dense(1,1);
    end
    function v = get_name_in(self, i)
      v = 'x2';
    end
    function v = get_jacobian(self,name,opts)
      disp('get jacobian called')
      x = casadi.MX.sym('x');
      v = casadi.Function('jac_x2',{x},{2*x});
    end
    function v = has_jacobian(self)
      v = true;
    end
  end
end