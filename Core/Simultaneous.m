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
    
    integratorMap
    pathconstraintsMap
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
      
      self.integratorMap = integrator.integratorFun.map(self.N);
      self.pathconstraintsMap = ocpHandler.pathConstraintsFun.map(self.N);
      
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
      
      % Final time tf is the first of the parameters
      tf = nlpVars(self.nv-self.np+1);
      
      H = hNormalized*tf;
      p = nlpVars(self.nv-self.np+1:self.nv);
      
      % Finds indizes of the variables in the NlpVars array.
      % cellfun is similar to python list comprehension 
      % e.g. [range(start_i,start_i+nx) for start_i in range(1,nv,nci)]
      X_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.nx)', 1:nci:self.nv-self.np, 'UniformOutput', false));
      I_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.ni)', self.nx+1:nci:self.nv-self.np, 'UniformOutput', false));
      U_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.nu)', self.nx+self.ni+1:nci:self.nv-self.np, 'UniformOutput', false));
      
      X = nlpVars(X_indizes);
      I = nlpVars(I_indizes);
      U = nlpVars(U_indizes);
      P = repmat(p,1,self.N);
      
      T0 = cumsum(hControls);
      
      % path constraints on first and last state
      pc0 = {};
      pc0_lb = {};
      pc0_ub = {};
      pcf = {};
      pcf_lb = {};
      pcf_ub = {};
      if self.options.path_constraints_at_boundary
        [pc0, pc0_lb, pc0_ub] = self.ocpHandler.pathConstraintsFun.evaluate(X(:,1), p);   
        [pcf,pcf_lb,pcf_ub] = self.ocpHandler.pathConstraintsFun.evaluate(X(:,end), p);   
      end         
      
      [xend_arr, ~, cost_arr, int_eq_arr, ~] = self.integratorMap(X, I, U, T0, H, P);
      [pc_eq_arr, pc_lb_arr, pc_ub_arr] = self.pathconstraintsMap(X, P);   
      
      % continuity
      continuity = xend_arr - X(:,2:end);
      continuity_lb = zeros(numel(continuity),1);
      continuity_ub = zeros(numel(continuity),1);
      
      % merge integrator equations and path concstraints
      shooting_eq = [int_eq_arr,pc_eq_arr(1:end-1)].';
      shooting_eq_lb = [zeros(numel(int_eq_arr),1),pc_lb_arr(1:end-1)].';
      shooting_eq_ub = [zeros(numel(int_eq_arr),1),pc_ub_arr(1:end-1)].';
      
      shooting_eq = [shooting_eq(:); pc_eq_arr(end)];
      shooting_eq_lb = [shooting_eq_lb(:); pc_lb_arr(end)];
      shooting_eq_ub = [shooting_eq_ub(:); pc_ub_arr(end)];
      
      % add terminal cost
      costf = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,p);

      % add boundary constraints
      [bc,bc_lb,bc_ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialStates,thisStates,p);
      
      costD = self.ocpHandler.discreteCostsFun.evaluate(nlpVars);    
      
      constraints = vertcat(pc0, shooting_eq(:), pcf, bc);
      constraints_LB = vertcat(pc0_lb, shooting_eq_lb, pcf_lb, bc_lb);
      constraints_UB = vertcat(pc0_ub, shooting_eq_ub, pcf_ub, bc_ub);
      
      % sum all costs
      costs = sum(cost_arr) + costf + costD;
      
    end % getNLPFun    
  end % methods
end % classdef

