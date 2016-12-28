classdef Multishooting < NLP
  %MULTISHOOTING Multi-shooting discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    ocpHandler
    modelIntegrator
    N
    
    nx
    nz
    nu
    
    nlpVars
  end
  
  methods
    
    function self = Multishooting(ocp,integrator,N)
      
      self = self@NLP();
      self.ocpHandler = OCPHandler(ocp);
      self.modelIntegrator = integrator;
      self.N = N;
      
      self.nx = prod(ocp.model.state.size);
      self.nu = prod(ocp.model.controls.size);
      self.nz = prod(ocp.model.algState.size);
      
      state = Var('state', [self.nx 1]);
      controls = Var('controls', [self.nu 1]);
      algVars = Var('algVars',[self.nz 1]);
      
      self.nlpVars = Var('nlpVars');
      self.nlpVars.addRepeated([state,algVars,controls],self.N);
      self.nlpVars.add(state);
      
      if strcmp(ocp.endTime, 'free')
        timeVar = Var('time',[1 1]);
        self.nlpVars.add(timeVar);
      end
      
    end
    
    function initialGuess = getInitialGuess(self)
      
      initialGuess = Var('nlpVars');
      initialGuess.addRepeated([self.ocpHandler.ocp.model.state,self.ocpHandler.ocp.model.algState,self.ocpHandler.ocp.model.controls],self.N);
      initialGuess.add(self.ocpHandler.ocp.model.state);
      
      
      if strcmp(self.ocpHandler.ocp.endTime, 'free')
        timeVar = Var('time',[1 1]);
        initialGuess.add(timeVar);
      end
      
      initialGuess.compile;
      
      initialGuess.set(0);
      
      [lowerBounds,upperBounds] = self.ocpHandler.getBounds(initialGuess);
      
      guessValues = (lowerBounds.value + upperBounds.value) / 2; 
      guessValues(isnan(guessValues)) = 0 ;
      
      initialGuess.set(guessValues);
      
    end
    
    function [lowerBounds, upperBounds] = getBounds(self,nlpVars)
      
      [lowerBounds,upperBounds] = self.ocpHandler.getBounds(nlpVars);
      
    end
       
    function [cost,constraints,constraints_LB,constraints_UB] = evaluate(self,varValues)
      
      
      if strcmp(self.ocpHandler.ocp.endTime, 'free')
        h = varValues(end) / self.N;
      else
        h = self.ocpHandler.ocp.endTime / self.N;
      end
      
      thisTime = 0;
      
      constraints = [];
      constraints_LB = [];
      constraints_UB = [];
      cost = 0;
           

      thisState = varValues(1:self.nx,1);
      curIndex = self.nx;
      
      for k=1:self.N

        thisAlgVar = varValues(curIndex+1:curIndex+self.nz);
        curIndex = curIndex+self.nz;
        
        thisControl = varValues(curIndex+1:curIndex+self.nu);
        curIndex = curIndex+self.nu;
        
        % add path cost
        lagrangeCost = self.ocpHandler.getLagrangeCost(thisState, thisAlgVar, thisControl, thisTime);
        cost = cost + lagrangeCost;
        
        % add path constraints
        [pathConstraint,lb,ub] = self.ocpHandler.getPathConstraints(thisState, thisAlgVar, thisControl,thisTime);
        constraints = [constraints; pathConstraint];
        constraints_LB = [constraints_LB; lb];
        constraints_UB = [constraints_UB; ub];
        
        % integrate on step
        [nextState,thisAlgVarOut] = self.modelIntegrator.evaluate(thisState,thisAlgVar,thisControl,h);

        thisState = varValues(curIndex+1:curIndex+self.nx);
        curIndex = curIndex+self.nx;

        % add continuity constraint
        constraints = [constraints; nextState - thisState];
        constraints_LB = [constraints_LB; zeros(self.nx,1)];
        constraints_UB = [constraints_UB; zeros(self.nx,1)];

        
        
        thisTime = thisTime + h;

      end
      
      % add terminal cost
      mayCost = self.ocpHandler.getMayerCost(thisState, thisTime);
      cost = cost + mayCost;

      % add terminal constraints
      [terminalConstraint,lb,ub] = self.ocpHandler.getTerminalConstraints(thisState,thisTime);
      constraints = [constraints; terminalConstraint];
      constraints_LB = [constraints_LB; lb];
      constraints_UB = [constraints_UB; ub];

    end % construct
    
    
  end
  
end

