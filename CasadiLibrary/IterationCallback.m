classdef IterationCallback < casadi.Callback
  properties
    nx
    ng
    np
    callbackFun
  end
  methods
    function self = IterationCallback(name,nx,ng,np,callbackFun)
      
      self@casadi.Callback();
      
      self.nx = nx;
      self.ng = ng;
      self.np = np;
      self.callbackFun = callbackFun;
      
      opts.input_scheme = casadi.nlpsol_out();
      opts.output_scheme = {'ret'};
      self.construct(name,opts);
    end
    
    function v=get_n_in(self)
      v=casadi.nlpsol_n_out;
    end
    function v = get_n_out(self)
      v = 1;
    end
    
    function v = get_sparsity_in(self, i)
      n = casadi.nlpsol_out(i);
      if n=='f'
        v =  casadi.Sparsity.scalar();
      elseif strcmp(n,'x') || strcmp(n,'lam_x')
        v = casadi.Sparsity.dense(self.nx);
      elseif strcmp(n,'g') || strcmp(n,'lam_g')
        v = casadi.Sparsity.dense(self.ng);
      elseif strcmp(n,'lam_p')
        v = casadi.Sparsity.dense(self.np);
      else
        v = casadi.Sparsity(0,0);
      end
    end

    function v = eval(self, arg)
      self.callbackFun(full(arg{1}));
      v = {0};
    end
  end
end