classdef CasadiNLP < handle
  
  properties (Access = private)

    ocpHandler
    integrator
    discretizationMethod

    pathConstraintsCasadiFun
    termConstraintsCasadiFun
    pathCostsCasadiFun
    termialCostsCasadiFun
    integratorCasadiFun

    nlpCostsCasadiFun
    nlpConstraintsCasadiFun

    pathCLB
    pathCUB
    termCLB
    termCUB

    nlpCosts
    nlpConstraints
    nlpConstraints_LB
    nlpConstraints_UB
  end
  
  methods
    
    function self = CasadiNLP(ocpHandler,integrator,discretizationMethod)
      
      self.ocpHandler = ocpHandler;
      self.integrator = integrator;
      self.discretizationMethod = discretizationMethod;
      self.construct;
    end

    function nv = getNumberOfVariables(self)
      nv = self.discretizationMethod.getNumberOfVariables;
    end

    function costs = costsFun(self,vars,parameters)
      costs = self.nlpCostsCasadiFun(vars,parameters);
    end

    function constraints = constraintsFun(self,vars,parameters)
      constraints = self.nlpConstraintsCasadiFun(vars,parameters);
    end

    function [lb,ub] = getConstraintsBounds(self)
      lb = self.nlpConstraints_LB;
      ub = self.nlpConstraints_UB;
    end

  end

  methods (Access = private)

    function construct(self)

      nv = self.discretizationMethod.getNumberOfVars;
      v = casadi.MX.sym('v',nv,1);

      nx = self.discretizationMethod.nx;
      ni = self.discretizationMethod.ni;
      nz = self.discretizationMethod.nz;
      nu = self.discretizationMethod.nu;
      np = self.discretizationMethod.np;

      x = casadi.MX.sym('x',nx,1);
      z = casadi.MX.sym('z',nz,1);
      xi = casadi.MX.sym('xi',ni,1);
      u = casadi.MX.sym('u',nu,1);
      p = casadi.MX.sym('p',np,1);
      t = casadi.MX.sym('t',1,1);
      tf = casadi.MX.sym('tf',1,1);


      [pathConstraints,self.pathCLB,self.pathCUB]  = self.ocpHandler.pathConstraintsFun(x,z,u,t,p);
      self.pathConstraintsCasadiFun = casadi.Function('pathConsFun',{x,z,y,t,p},{pathConstraints});
      self.pathConstraintsCasadiFun = self.pathConstraintsCasadiFun.expand();

      [termConstraints,self.termCLB,self.termCUB] = self.ocpHandler.terminalConstraintsFun(x,t,p);
      self.termConstraintsCasadiFun = casadi.Function('termConsFun',{x,t,p},{termConstraints});

      pathCosts = self.ocpHandler.pathCostsFun(x,z,u,t,p);
      self.pathCostsCasadiFun = casadi.Function('pathCostsFun',{x,z,u,t,p},{pathCosts});

      terminalCosts = self.ocpHandler.terminalCostsFun(x,t,p);
      self.termialCostsCasadiFun = casadi.Function('termCostsFun',{x,t,p},{terminalCosts});

      [finalState, finalAlgVars, costs, equations] = self.integrator.evaluate(x,xi,u,t,tf,p);
      self.integratorCasadiFun = casadi.Function('integratorFun',{x,xi,u,t,tf,p},{finalState,finalAlgVars,costs,equations});


      self.discretizationMethod.setFunctionHandles(@pathConstraintsFun,@terminalConstraintsFun, ...
                                                   @pathCostsFun,@terminalCostsFun, ...
                                                   @integratorFun);

      [nlpCosts,nlpConstraints,self.nlpConstraints_LB,self.nlpConstraints_UB] = self.discretizationMethod.evaluate(v,p);

      self.nlpCostsCasadiFun = casadi.Function('nlpCostsFun',{v,p},{nlpCosts});
      self.nlpConstraintsCasadiFun = casadi.Function('nlpConsFun',{v,p},{nlpConstraints});

    end



    function [c,lb,ub] = pathConstraintsFun(self,state,algState,controls,time,parameters)
      c = self.pathConstraintsCasadiFun(state,algState,controls,time,parameters);
      lb = self.pathCLB;
      ub = self.pathCUB;
    end
    
    function [c,lb,ub] = terminalConstraintsFun(self,state,time,parameters)
      c = self.termConstraintsCasadiFun(state,time,parameters);
      lb = self.termCLB;
      ub = self.termCUB;
    end
    
    function pathCosts = pathCostsFun(self,state,algState,controls,time,parameters)
      pathCosts = self.pathCostsCasadiFun(state,algState,controls,time,parameters);
    end
    
    function terminalCosts = terminalCostsFun(self,state,time,parameters)
      terminalCosts = self.termialCostsCasadiFun(state,time,parameters);
    end

    function [finalState, finalAlgVars, costs, equations] = integratorFun(self,state,integratorVars,controls,time,finalTime,paramters)
      [finalState, finalAlgVars, costs, equations] = self.integratorCasadiFun(state,integratorVars,controls,time,finalTime,parameters);
    end

  end

end
