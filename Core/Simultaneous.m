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
    
    igAll
    ig0
    igF
    
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
      
      % N control interval which each have states, integrator vars,
      % controls, parameters, and timesteps.
      % Ends with a single state.
      self.nv = (N+1)*self.nx + N*self.ni + N*self.nu + N*self.np + N;
      
      self.nit = integrator.nt; % number of integrator timepoints
      
      self.integratorFun = integrator.integratorFun;
      
      self.varsStruct = OclStructure();
      self.varsStruct.addRepeated({'states','integrator','controls','parameters','h','T'}, ...
                                  {system.statesStruct, ...
                                   integrator.varsStruct, ...
                                   system.controlsStruct, ...
                                   system.parametersStruct, ...
                                   OclMatrix([1,1])}, self.N);
      self.varsStruct.add('states',system.statesStruct);
      
      self.timesStruct = OclStructure();
      self.timesStruct.addRepeated({'states','integrator','controls'},...
                                   {OclMatrix([1,1]),OclMatrix([self.nit,1]),OclMatrix([1,1])},self.N);
      self.timesStruct.add('states',OclMatrix([1,1]));

      fh = @(self,varargin)self.getNLPFun(varargin{:});
      self.nlpFun = OclFunction(self,fh,{[self.nv,1]},5);
      
      self.igAll = struct;
      self.ig0 = struct;
      self.igF = struct;
      
    end
    
    function setBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.ocpHandler.setBounds(id,varargin{:})
      self.ig.(id) = mean([varargin{:}]);
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.ocpHandler.setInitialBounds(id,varargin{:});
      self.ig0.(id) = mean([varargin{:}]);
    end
    
    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.ocpHandler.setEndBounds(id,varargin{:})
      self.igF.(id) = mean([varargin{:}]);
    end    
    
    function setInitialGuess0(self, id, value)
      self.ig0.(id) = value;
    end
    
    function setInitialGuessF(self, id, value)
      self.igF.(id) = value;
    end
    
    function setInitialGuess(self, id, value)
      self.igAll.(id) = value;
    end
    
    function ig = ig(self)
      ig = self.getInitialGuess();
    end
    
    function initialGuess = getInitialGuess(self)
      
      initialGuess = NlpValues.create(self.varsStruct,0);
      
      [lb,ub] = self.getNlpBounds();
      
      guessValues = (lb + ub) / 2;
      
      % set to lowerBounds if upperBounds are inf
      indizes = isinf(ub);
      guessValues(indizes) = lb(indizes);
      
      % set to upperBounds of lowerBounds are inf
      indizes = isinf(lb);
      guessValues(indizes) = ub(indizes);
      
      % set to zero if both lower and upper bounds are inf
      indizes = isinf(lb) & isinf(ub);
      guessValues(indizes) = 0;
      
      % apply manual set ig
      igFlat = NlpValues.create(self.varsStruct.flat(),guessValues);
      
      % ig at end (set everywhere)
      names = fieldnames(self.igF);
      for i=1:length(names)
        id = names{i};
        igFlat.get(id).set(self.igF.(id));
      end
      
      % ig at start (set everywhere except end)
      names = fieldnames(self.ig0);
      for i=1:length(names)
        id = names{i};
        igId = igFlat.get(id);
        igId(:,:,1:end-1).set(self.ig0.(id));
      end
      
      % ig general (set everywhere except start and end)
      names = fieldnames(self.ig);
      for i=1:length(names)
        id = names{i};
        igId = igFlat.get(id);
        igId(:,:,2:end-1).set(self.igAll.(id));
      end
      
      initialGuess.set(igFlat.value());
      
      % ig for timesteps
      if isempty(self.ocpHandler.T)
        H = self.ocpHandler.H_norm;
      else
        H = self.ocpHandler.H_norm.*self.ocpHandler.T;
      end
      initialGuess.get('h').set(H);
      
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
      
      % system parameter bounds
      names = fieldnames(self.system.parameterBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,1).set(self.system.parameterBounds.(id).lower);
        ub(:,:,1).set(self.system.parameterBounds.(id).upper);
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
      % + 1 for the timestep
      nci = self.nx+self.ni+self.nu+self.np+1;
      
      % Finds indizes of the variables in the NlpVars array.
      % cellfun is similar to python list comprehension 
      % e.g. [range(start_i,start_i+nx) for start_i in range(1,nv,nci)]
      X_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.nx-1)', 1:nci:self.nv, 'UniformOutput', false));
      I_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.ni-1)', self.nx+1:nci:self.nv, 'UniformOutput', false));
      U_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.nu-1)', self.nx+self.ni+1:nci:self.nv, 'UniformOutput', false));
      P_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+self.np-1)', self.nx+self.ni+self.nu+1:nci:self.nv, 'UniformOutput', false));
      H_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i)', self.nx+self.ni+self.nu+self.np+1:nci:self.nv, 'UniformOutput', false));
      
      X = reshape(nlpVars(X_indizes), self.nx, self.N+1);
      I = reshape(nlpVars(I_indizes), self.ni, self.N);
      U = reshape(nlpVars(U_indizes), self.nu, self.N);
      P = reshape(nlpVars(P_indizes), self.np, self.N);
      H = reshape(nlpVars(H_indizes), 1      , self.N);
      
      % path constraints on first and last state
      pc0 = [];
      pc0_lb = [];
      pc0_ub = [];
      pcf = [];
      pcf_lb = [];
      pcf_ub = [];
      if self.options.path_constraints_at_boundary
        [pc0, pc0_lb, pc0_ub] = self.ocpHandler.pathConstraintsFun.evaluate(X(:,1), P(:,1));
        [pcf,pcf_lb,pcf_ub] = self.ocpHandler.pathConstraintsFun.evaluate(X(:,end), P(:,end));
      end         
      
      T0 = [0, cumsum(H(:,1:end-1))];
      
      [xend_arr, ~, cost_arr, int_eq_arr, int_times] = self.integratorMap.evaluate(X(:,1:end-1), I, U, T0, H, P);
      [pc_eq_arr, pc_lb_arr, pc_ub_arr] = self.pathconstraintsMap.evaluate(X(:,2:end-1), P(:,2:end));
                
      % timestep constraints
      h_eq = [];
      h_eq_lb = [];
      h_eq_ub = [];
      
      if isempty(self.ocpHandler.T)
        % normalized timesteps (sum of timesteps is 1)
        H_norm = self.ocpHandler.H_norm;
        
        % h0 = h_1_hat / h_0_hat * h1 = h_2_hat / h_1_hat * h2 ...
        H_ratio = H_norm(1:end-1)./H_norm(2:end);
        h_eq = H_ratio .* H(:,2:end) - H(:,1:end-1);
        h_eq_lb = zeros(1, self.N-1);
        h_eq_ub = zeros(1, self.N-1);
      end
      
      % Parameter constraints 
      % p0=p1=p2=p3 ...
      p_eq = P(:,2:end)-P(:,1:end-1);
      p_eq_lb = zeros(self.np, self.N-1);
      p_eq_ub = zeros(self.np, self.N-1);
      
      % continuity (nx x N)
      continuity = xend_arr - X(:,2:end);
      
      % merge integrator equations, continuity, and path constraints,
      % timesteps constraints
      shooting_eq    = [int_eq_arr(:,1:self.N-1);  continuity(:,1:self.N-1);  pc_eq_arr;  h_eq;     p_eq];
      shooting_eq_lb = [zeros(self.ni,self.N-1);   zeros(self.nx,self.N-1);   pc_lb_arr;  h_eq_lb;  p_eq_lb];
      shooting_eq_ub = [zeros(self.ni,self.N-1);   zeros(self.nx,self.N-1);   pc_ub_arr;  h_eq_ub;  p_eq_ub];
      
      % reshape shooting equations to column vector, append final integrator and
      % continuity equations
      shooting_eq    = [shooting_eq(:);    int_eq_arr(:,self.N); continuity(:,self.N)];
      shooting_eq_lb = [shooting_eq_lb(:); zeros(self.ni,1);     zeros(self.nx,1)    ];
      shooting_eq_ub = [shooting_eq_ub(:); zeros(self.ni,1);     zeros(self.nx,1)    ];
      
      % boundary constraints
      [bc,bc_lb,bc_ub] = self.ocpHandler.boundaryConditionsFun.evaluate(X(:,1),X(:,end),P(:,1));
      
      % collect all constraints
      constraints = vertcat(pc0, shooting_eq, pcf, bc);
      constraints_LB = vertcat(pc0_lb, shooting_eq_lb, pcf_lb, bc_lb);
      constraints_UB = vertcat(pc0_ub, shooting_eq_ub, pcf_ub, bc_ub);
      
      % terminal cost
      costf = self.ocpHandler.arrivalCostsFun.evaluate(X(:,end),P(:,end));
      
      % discrete cost
      costD = self.ocpHandler.discreteCostsFun.evaluate(nlpVars); 
      
      % sum all costs
      costs = sum(cost_arr) + costf + costD;
      
      % times
      times = [T0; int_times; T0];
      times = [times(:); T0(end)+H(end)];
      
    end % getNLPFun    
  end % methods
end % classdef

