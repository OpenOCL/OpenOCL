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
      
      if isempty(self.ocpHandler.T)
        T = nlpVars(self.nv-self.np);
      else
        T = self.ocpHandler.T;
      end
      
      timeConstraints = {T};
      timeConstraints_LB = {0};
      timeConstraints_UB = {inf};
      timeCost = 0;
      
      if self.system.options.dependent && isempty(self.ocpHandler.T)
        timeGrid = nlpVars(1:self.ni+self.nu+self.nx:end-self.np);
        timeConstraints = {timeGrid(1),timeGrid(end)-T,timeGrid(2:end)-timeGrid(1:end-1)};
        timeConstraints_LB = {0,0,zeros(self.N,1)};
        timeConstraints_UB = {0,0,inf * ones(self.N,1)};
        
        x = timeGrid(2:end)-timeGrid(1:end-1);
        timeCost = sum((x-mean(x).^2)); % sum(x-xmean)^2
      else
        timeGrid = linspace(0,T,self.N+1);
      end
      
      
      
      parameters = nlpVars(self.nv-self.np:self.nv-1);
      
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
        
        times{kt_states} = timeGrid(k);
        times{kt_controls} = timeGrid(k);
         
        thisIntegratorVars = nlpVars(k_vars+1:k_vars+self.ni);
        k_vars = k_vars+self.ni;
        thisControls = nlpVars(k_vars+1:k_vars+self.nu);
        k_vars = k_vars+self.nu;
        
        % add integrator equations
        [endStates, ~, integrationCosts, integratorEquations, integratorTimes] = ...
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
      end
      
      times{end} = T;
      times = vertcat(times{:});
      
      % add terminal cost
      terminalCosts = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,parameters);
      costs = costs + terminalCosts;

      % add boundary constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialStates,thisStates,parameters);
      constraints{nc} = boundaryConditions;
      constraints_LB{nc} = lb;
      constraints_UB{nc} = ub;
      
      costs = costs + self.ocpHandler.discreteCostsFun.evaluate(nlpVars) + 1e3*timeCost;    
      
      constraints = vertcat(constraints{:},timeConstraints{:});
      constraints_LB = vertcat(constraints_LB{:},timeConstraints_LB{:});
      constraints_UB = vertcat(constraints_UB{:},timeConstraints_UB{:});
    end % getNLPFun
  end % methods
end % classdef

