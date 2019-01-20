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
    options
  end
  
  properties(Access = private)
    N
    nx
    ni
    nu
    np
    nit
  end
  
  methods
    function self = Simultaneous(system,ocpHandler,integrator,N,options)
      
      self.system = system;
      self.ocpHandler = ocpHandler;
      self.N = N;
      self.options = options;
      self.nx = prod(system.statesStruct.size());
      self.ni = prod(integrator.varsStruct.size());
      self.nu = prod(system.controlsStruct.size());
      self.np = prod(system.parametersStruct.size());
      self.nv = (N+1)*self.nx + N*self.ni + N*self.nu+self.np;
      self.nit = integrator.nt; % number of integrator timepoints
      
      self.integratorFun = integrator.integratorFun;
      
      self.varsStruct = OclStructure();
      self.varsStruct.addRepeated({'states','integrator','controls'},...
                                      {system.statesStruct,...
                                      integrator.varsStruct,...
                                      system.controlsStruct},self.N);
      self.varsStruct.add('states',system.statesStruct);
      
      self.varsStruct.add('parameters',system.parametersStruct);
      
      self.timesStruct = OclStructure();
      self.timesStruct.addRepeated({'states','integrator','controls'},...
                                   {OclMatrix([1,1]),OclMatrix([self.nit,1]),OclMatrix([1,1])},self.N);
      self.timesStruct.add('states',OclMatrix([1,1]));

      fh = @(self,varargin)self.getNLPFun(varargin{:});
      self.nlpFun = OclFunction(self,fh,{[self.nv,1]},5);
      
    end
    
    function setBounds(self,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.ocpHandler.setBounds(varargin{:})
    end
    
    function setInitialBounds(self,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.ocpHandler.setInitialBounds(varargin{:})
    end
    
    function setEndBounds(self,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.ocpHandler.setEndBounds(varargin{:})
    end    
    
    function [lowerBounds,upperBounds] = getNlpBounds(self)
      
      boundsStruct = self.varsStruct.flat();
      lowerBounds = Variable.create(boundsStruct,-inf);
      upperBounds = Variable.create(boundsStruct,inf);
      
      % system bounds
      names = fieldnames(self.system.bounds);
      for i=1:length(names)
        id = names{i};
        lowerBounds.get(id).set(self.system.bounds.(id).lower);
        upperBounds.get(id).set(self.system.bounds.(id).upper);
      end
      
      % solver bounds
      names = fieldnames(self.ocpHandler.bounds);
      for i=1:length(names)
        id = names{i};
        lowerBounds.get(id).set(self.ocpHandler.bounds.(id).lower);
        upperBounds.get(id).set(self.ocpHandler.bounds.(id).upper);
      end
      
      % initial bounds
      names = fieldnames(self.ocpHandler.initialBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,1).set(self.ocpHandler.initialBounds.(id).lower);
        ub(:,:,1).set(self.ocpHandler.initialBounds.(id).upper);
      end
      
      % end bounds
      names = fieldnames(self.ocpHandler.endBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,end).set(self.ocpHandler.endBounds.(id).lower);
        ub(:,:,end).set(self.ocpHandler.endBounds.(id).upper);
      end
      
      lowerBounds = lowerBounds.value;
      upperBounds = upperBounds.value;
      
    end
    
    function [costs,constraints,constraints_LB,constraints_UB,times] = getNLPFun(self,nlpVars)
  
      % number of variables in one control interval
      nci = self.nx+self.ni+self.nu;
      
      % h_normalized is the first of the controls
      hNormalized = nlpVars(self.nx+self.ni+1:nci:self.N*nci); 
      % T is the first of the parameters
      T = nlpVars(self.nv-self.np+1);
      
      hControls = hNormalized*T;
      
      parameters = nlpVars(self.nv-self.np+1:self.nv);
      
      % N+1 state times
      % N integrator times
      % N control times
      times = cell((self.N+1)+self.N+self.N,1);
      
      % N integrator equations
      % N+1 path constraints
      % N continuity constraints
      % 1 boundary condition
      nc = 3*self.N+2;
      constraints = cell(nc,1);
      constraints_LB = cell(nc,1);
      constraints_UB = cell(nc,1);
      
      costs = 0;
      time = 0;
      initialStates = nlpVars(1:self.nx);
      thisStates = initialStates;
      k_vars = self.nx;
      
      if self.options.path_constraints_at_boundary
        [pathConstraint,lb,ub] = ...
              self.ocpHandler.pathConstraintsFun.evaluate(thisStates,...
                                                          parameters);   
        constraints{1} = pathConstraint;
        constraints_LB{1} = lb;
        constraints_UB{1} = ub;
      end                                          
      
      for k=1:self.N
        k_integratorEquations = 3*(k-1)+2;
        k_pathConstraints = 3*(k-1)+3;
        k_continuity = 3*(k-1)+4;
        
        kt_states = 3*(k-1)+1;
        kt_integrator = 3*(k-1)+2;
        kt_controls = 3*(k-1)+3;
        
        times{kt_states} = time;
        times{kt_controls} = time;
        
        thisIntegratorVars = nlpVars(k_vars+1:k_vars+self.ni);
        k_vars = k_vars+self.ni;
        thisControls = nlpVars(k_vars+1:k_vars+self.nu);
        k_vars = k_vars+self.nu;
        
        % add integrator equations
        [endStates, ~, integrationCosts, integratorEquations, integratorTimes] = ...
              self.integratorFun.evaluate(thisStates,...
                                          thisIntegratorVars,...
                                          thisControls,...
                                          time,...
                                          hControls(k),...
                                          parameters);
                                          
        times{kt_integrator} = integratorTimes;
                                          
        constraints{k_integratorEquations} = integratorEquations;
        constraints_LB{k_integratorEquations} = zeros(size(integratorEquations));
        constraints_UB{k_integratorEquations} = zeros(size(integratorEquations));
        
        costs = costs + integrationCosts;
        
        % go to next time gridpoint
        thisStates = nlpVars(k_vars+1:k_vars+self.nx);
        k_vars = k_vars+self.nx;
        
        if k~=self.N || self.options.path_constraints_at_boundary
          % add path constraints
          [pathConstraint,lb,ub] = ...
                self.ocpHandler.pathConstraintsFun.evaluate(thisStates,...
                                                            parameters);                                   
          constraints{k_pathConstraints} = pathConstraint;
          constraints_LB{k_pathConstraints} = lb;
          constraints_UB{k_pathConstraints} = ub;
        end
        
        % continuity equation
        continuity_constraint = endStates - thisStates;
        constraints{k_continuity} = continuity_constraint;
        constraints_LB{k_continuity} = zeros(size(continuity_constraint));
        constraints_UB{k_continuity} = zeros(size(continuity_constraint));
        
        time = time + hControls(k);
        
      end
      
      times{end} = time;
      times = vertcat(times{:});
      
      % add terminal cost
      terminalCosts = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,parameters);
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

