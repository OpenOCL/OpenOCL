classdef Simultaneous < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    nlpFun
    varsStruct
    timesStruct
    ocpHandler
    integratorFun
    nv
    system
  end
  
  properties(Access = private)
    scalingMin
    scalingMax
    N
    nx
    ni
    nu
    np
    nit
  end
  
  methods
    function self = Simultaneous(system,integrator,N)
      
      self.system = system;
      self.N = N;
      self.nx = prod(system.statesStruct.size());
      self.ni = prod(integrator.varsStruct.size());
      self.nu = prod(system.controlsStruct.size());
      self.np = prod(system.parametersStruct.size());
      self.nv = (N+1)*self.nx + N*self.ni + N*self.nu+self.np+1;
      self.nit = integrator.nt;
      
      self.integratorFun = integrator.integratorFun;
      
      self.varsStruct = OclStructure();
      self.varsStruct.addRepeated({'states','integrator','controls'},...
                                      {system.statesStruct,...
                                      integrator.varsStruct,...
                                      system.controlsStruct},self.N);
      self.varsStruct.add('states',system.statesStruct);
      
      self.varsStruct.add('parameters',system.parametersStruct);
      self.varsStruct.add('time',[1 1]);
      
      self.timesStruct = OclStructure();
      self.timesStruct.addRepeated({'states','integrator','controls'},...
                                   {OclMatrix([1,1]),OclMatrix([self.nit,1]),OclMatrix([1,1])},self.N);
      self.timesStruct.add('states',OclMatrix([1,1]));
      
      % initialize bounds      
      nlpVarsFlatFlat = self.varsStruct.flat();
      
      self.scalingMin = Variable.create(nlpVarsFlatFlat,0);
      self.scalingMax = Variable.create(nlpVarsFlatFlat,1);
      
      fh = @(self,varargin)self.getNLPFun(varargin{:});
      self.nlpFun = OclFunction(self,fh,{[self.nv,1]},5);
    end    
    
    function [scalingMin,scalingMax] = getScaling(self)
      scalingMin = self.scalingMin;
      scalingMax = self.scalingMax;
    end
    
    function interpolateGuess(self,guess)
      for i=1:self.N
        state = guess.states(:,:,i).value;
        guess.integrator(:,:,i).states.set(state);
      end
    end
    
    function setParameter(self,id,varargin)
      % setParameter(id,lower,upper)
      % setParameter(id,value)     
      self.setBound(id,'all',varargin{:},false)
    end
    
    function setVariableScaling(self,id,varargin)
      % setVariableScaling(id,lower,upper)
      % setVariableScaling(id,value)     
      self.setScaling(id,'all',varargin{:})
    end
    
    function setScaling(self,id,slice,valMin,valMax)
      
      if valMin == valMax
        error('Can not scale with zero range for the variable');
      end
      self.scalingMin.get(id,slice).set(valMin);
      self.scalingMax.get(id,slice).set(valMax);     
    end
    
    function checkScaling(self)
      
      if any(isinf(self.scalingMin.value)) || any(isinf(self.scalingMax.value))
        error('Scaling information for some variable missing. Provide scaling for all variables or set scaling option to false.');
      end
      
    end
    
    function getCallback(self,var,values)
      self.ocpHandler.callbackFunction(var,values);
    end

    function [costs,constraints,constraints_LB,constraints_UB,times] = getNLPFun(self,nlpVars)
      
      T = nlpVars(self.nv);
      parameters = nlpVars(self.nv-self.np:self.nv-1);

      timeGrid = linspace(0,T,self.N+1);
      
      % N+1 state times
      % N integrator times
      % N control times
      times = cell((self.N+1)+self.N+self.N);
      
      % N integrator equations
      % N path constraints
      % N continuity constraints
      % 1 boundary condition
      nc = 3*self.N+1;
      constraints = cell(nc,1);
      constraints_LB = cell(nc,1);
      constraints_UB = cell(nc,1);
      
      costs = 0;
      initialStates = nlpVars(1:self.nx);
      thisStates = initialStates;
      k_vars = self.nx;
      for k=1:self.N
        k_integratorEquations = 3*(k-1)+1;
        k_pathConstraints = 3*(k-1)+2;
        k_continuity = 3*(k-1)+3;
        
        kt_states = 3*(k-1)+1;
        kt_integrator = 3*(k-1)+2;
        kt_controls = 3*(k-1)+3;
        
        times{kt_states} = timeGrid(k);
        times{kt_controls} = timeGrid(k);
         
        thisIntegratorVars = nlpVars(k_vars+1:k_vars+self.ni);
        k_vars = k_vars+self.ni;
        thisControls = nlpVars(k_vars+1:k_vars+self.nu);
        k_vars = k_vars+self.nu;
        
        % add integrator equations
        [endStates, endAlgVars, integrationCosts, integratorEquations, integratorTimes] = ...
              self.integratorFun.evaluate(thisStates,...
                                          thisIntegratorVars,...
                                          thisControls,...
                                          timeGrid(k),...
                                          timeGrid(k+1),...
                                          T,parameters);
                                          
        times{kt_integrator} = integratorTimes;
                                          
        constraints{k_integratorEquations} = integratorEquations;
        constraints_LB{k_integratorEquations} = zeros(size(integratorEquations));
        constraints_UB{k_integratorEquations} = zeros(size(integratorEquations));
        
        costs = costs + integrationCosts;
        
        % go to next time gridpoint
        thisStates = nlpVars(k_vars+1:k_vars+self.nx);
        k_vars = k_vars+self.nx;
        
        % add path constraints
        [pathConstraint,lb,ub] = ...
              self.ocpHandler.pathConstraintsFun.evaluate(thisStates,... 
                                                          endAlgVars,...
                                                          thisControls,...
                                                          timeGrid(k+1),...
                                                          parameters);                                   
        constraints{k_pathConstraints} = pathConstraint;
        constraints_LB{k_pathConstraints} = lb;
        constraints_UB{k_pathConstraints} = ub;
        
        % continuity equation
        continuity_constraint = endStates - thisStates;
        constraints{k_continuity} = continuity_constraint;
        constraints_LB{k_continuity} = zeros(size(continuity_constraint));
        constraints_UB{k_continuity} = zeros(size(continuity_constraint));
      end
      
      times{end} = T;
      times = vertcat(times{:});
      
      % add terminal cost
      terminalCosts = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,T,parameters);
      costs = costs + terminalCosts;

      % add boundary constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialStates,thisStates,parameters);
      constraints{nc} = boundaryConditions;
      constraints_LB{nc} = lb;
      constraints_UB{nc} = ub;
      
      costs = costs + self.ocpHandler.discreteCostsFun.evaluate(nlpVars);    
      
      constraints = vertcat(constraints{:});
      constraints_LB = vertcat(constraints_LB{:});
      constraints_UB = vertcat(constraints_UB{:});
    end % getNLPFun
  end % methods
end % classdef

