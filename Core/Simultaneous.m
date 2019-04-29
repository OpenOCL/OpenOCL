classdef Simultaneous < handle
  %SIMULTANEOUS Direct collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    varsStruct
    nlpFun
  end
  
  properties(Access = private)
    phaseList
    
    initialBounds
    endBounds
    bounds
    
    integratorMaps
    pathconstraintsMaps
    
    integratorFun
    system
    options
    
    integratorMap
    pathconstraintsMap
  end
  
  methods
    function self = Simultaneous(phaseList, options)
      
      self.phaseList = phaseList;
      self.options = options;
      
      self.varsStruct = self.getVarsStruct(phaseList);
      
      nv = 0;
      for k=1:self.numPhases
        phase = phaseList{k};
        N = length(phase.H_norm);
        nv = nv + N*phase.nx + N*phase.integrator.ni + N*phase.nu + N*phase.np + N + phase.nx;
      end
      
      fh = @(self,varargin)self.getNLPFun(varargin{:});
      self.nlpFun = OclFunction(self,fh,{[nv,1]},5);
      
      self.integratorMaps = cell(self.numPhases,1);
      self.pathconstraintsMaps = cell(self.numPhases,1);
      
      for k=1:self.numPhases
        phase = phaseList{k};
        phase.integrator.integratorfun = CasadiFunction(phase.integrator.integratorfun);
        phase.pathconfun = CasadiFunction(phase.pathconfun);
        self.integratorMaps{k} = CasadiMapFunction(phase.integrator.integratorfun, phase.N);
        self.pathconstraintsMaps{k} = CasadiMapFunction(phase.pathconfun, phase.N-1);

      end
    end
    
    function varsStruct = getVarsStruct(~, phaseList)
      
      varsStruct = OclStructure();
      phaseStruct = [];
      
      for k=1:length(phaseList)
        phase = phaseList{k};
        phaseStruct = OclStructure();
        phaseStruct.addRepeated({'states','integrator','controls','parameters','h'}, ...
                            {phase.states, ...
                             phase.integrator.vars, ...
                             phase.controls, ...
                             phase.parameters, ...
                             OclMatrix([1,1])}, length(phase.H_norm));
        phaseStruct.add('states', phase.states);

        varsStruct.add('phase', phaseStruct);
      end
      if length(phaseList) == 1
        varsStruct = phaseStruct;
      end
    end
    
    function timesStruct = getTimeStruct(~, nit, N)
      timesStruct = OclStructure();
      timesStruct.addRepeated({'states', 'integrator', 'controls'}, ...
                                   {OclMatrix([1,1]), OclMatrix([nit,1]), OclMatrix([1,1])}, N);
      timesStruct.add('states', OclMatrix([1,1]));
    end
    
    function setParameter(self,id,varargin)
      self.initialBounds = OclBound(id, varargin{:});
      self.igParameters.(id) = mean([varargin{:}]);
    end
    
    function setBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds = OclBounds(id, varargin{:});
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.initialBounds = OclBounds(id, varargin{:});
    end
    
    function setEndBounds(self,id,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.endBounds = OclBounds(id, varargin{:});
    end    
    
    function ig = ig(self)
      ig = self.getInitialGuess();
    end
    
    function guess = igFromBounds(~, bounds)
      % Averages the bounds to get an initial guess value.
      % Makes sure no nan values are produced, defaults to 0.
      guess = (bounds.lower + bounds.upper)/2;
      if isnan(guess) && ~isinf(bounds.lower)
        guess = bounds.lower;
      elseif isnan(guess) && ~isinf(bounds.upper)
        guess = bounds.upper;
      else
        guess = 0;
      end
    end
    
    function ig = getInitialGuess(self, ...
          varsStruct, phaseList)
      % creates an initial guess from the information that we have about
      % bounds, phases etc.
      
      ig = Variable.create(varsStruct,0);
      
      for k=1:length(phaseList)
        
        phase = phaseList{k};
        igPhase = ig.get('phases', k);
        
        names = fieldnames(phase.bounds);
        for l=1:length(names)
          id = names{l};
          igPhase.get(id).set(self.igFromBounds(phase.bounds.(id)));
        end
        
        names = fieldnames(phase.bounds0);
        for l=1:length(names)
          id = names{l};
          igPhase.get(id).set(self.igFromBounds(phase.bounds0.(id)));
        end
        
        names = fieldnames(phase.boundsF);
        for l=1:length(names)
          id = names{l};
          igPhase.get(id).set(self.igFromBounds(phase.boundsF.(id)));
        end

        % linearily interpolate guess
        phaseStruct = varsStruct.get('phases',k).flat();
        phaseFlat = Variable.create(phaseStruct.flat(), igPhase.value);
        
        names = igPhase.children();
        for i=1:length(names)
          id = names{i};
          igId = phaseFlat.get(id);
          igStart = igId(:,:,1).value;
          igEnd = igId(:,:,end).value;
          s = igId.size();
          gridpoints = reshape(linspace(0, 1, s(3)), 1, 1, s(3));
          gridpoints = repmat(gridpoints, s(1), s(2));
          interpolated = igStart + gridpoints.*(igEnd-igStart);
          phaseFlat.get(id).set(interpolated);
        end
        igPhase.set(phaseFlat.value);
        
        names = fieldnames(phase.parameterBounds);
        for i=1:length(names)
          id = names{i};
          igPhase.get(id).set(self.igFromBounds(phase.parameterBounds.(id)));
        end
        
        % ig for timesteps
        if isempty(phase.T)
          H = self.ocpHandler.H_norm;
        else
          H = self.ocpHandler.H_norm.*self.ocpHandler.T;
        end
        igPhase.get('h').set(H);
      
      end
    end
    
    function [lowerBounds,upperBounds] = getNlpBounds(self)
      
      boundsStruct = self.varsStruct.flat();
      lowerBounds = Variable.create(boundsStruct,-inf);
      upperBounds = Variable.create(boundsStruct,inf);
      
      % phase bounds
      for k=1:self.numPhases
        
        phase = self.phaseList{k};
        
        phase_lb = lowerBounds.get('phases', k);
        phase_ub = lowerBounds.get('phases', k);
        
        % timestep bounds
        if isempty(phase.T)
          phase_lb.get('h').set(Simultaneous.h_lower);
          phase_ub.get('h').set(inf);
        else
          phase_lb.get('h').set(phase.H_norm * phase.T);
          phase_ub.get('h').set(phase.H_norm * phase.T);
        end
        
        % variables bounds
        names = fieldnames(phase.bounds);
        for i=1:length(names)
          id = names{i};
          phase_lb.get(id).set(phase.bounds.(id).lower);
          phase_ub.get(id).set(phase.bounds.(id).upper);
        end
        
        % parameters bounds
        names = fieldnames(phase.parameterBounds);
        for i=1:length(names)
          id = names{i};
          lb = phase_lb.get(id);
          ub = phase_ub.get(id);
          lb(:,:,1).set(phase.parameterBounds.(id).lower);
          ub(:,:,1).set(phase.parameterBounds.(id).upper);
        end
        
      end

      % nlp bounds
      names = fieldnames(self.bounds);
      for i=1:length(names)
        id = names{i};
        lowerBounds.get(id).set(self.bounds.(id).lower);
        upperBounds.get(id).set(self.bounds.(id).upper);
      end
      
      names = fieldnames(self.initialBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,1).set(self.initialBounds.(id).lower);
        ub(:,:,1).set(self.initialBounds.(id).upper);
      end
      
      % end bounds
      names = fieldnames(self.endBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,end).set(self.endBounds.(id).lower);
        ub(:,:,end).set(self.endBounds.(id).upper);
      end
      
      lowerBounds = lowerBounds.value;
      upperBounds = upperBounds.value;
      
    end
    
    function [costs,constraints,constraints_LB,constraints_UB,times] = nlpfun(~, phaseList, nlpVars)
      
      numPhases = length(phaseList);
      
      nv = 0;
      for k=1:numPhases
        phase = phaseList{k};
        N = length(phase.H_norm);
        nv = nv + N*phase.nx + N*phase.integrator.ni + N*phase.nu + N*phase.np + N + phase.nx;
      end
      
      numStatesOfLastPhase = phaseList{numPhases}.nx;
      xF = nlpVars(nv-numStatesOfLastPhase:nv);
      
      costs = 0;
      
      constraints = cell(numPhases,1);
      constraints_LB = cell(numPhases,1);
      constraints_UB = cell(numPhases,1);
      
      varIndex = 1;
      for k=1:numPhases
        
        phase = phaseList{k};
        phaseVars = nlpVars(varIndex:varIndex + phase.numVars);
        
        [phaseCosts,phaseConstraints,phaseConstraints_LB,phaseConstraints_UB, times, x0, p0] = getPhaseEquations(phase, phaseVars);
        [bc, bc_lb, bc_ub] = phase.boundaryfun.evaluate(x0, xF, p0);
        
        constraints{k} = [phaseConstraints; bc];
        constraints_LB{k} = [phaseConstraints_LB; bc_lb];
        constraints_UB{k} = [phaseConstraints_UB; bc_ub];
        
        costs = costs + phaseCosts;
        
        varIndex = varIndex + phase.numVars;
        xF = x0;
      end
      
    end
    
    function [costs,constraints,constraints_LB,constraints_UB,times,x0,p0] = ...
        simultaneous(H_norm, T, nx, ni, nu, np, phaseVars, integrator_map, ...
                     arrivalcost_fun, pathcon_fun, pathcon_map, pathcostd_map, options)
      
      N = length(H_norm);
      
      % N control interval which each have states, integrator vars,
      % controls, parameters, and timesteps.
      % Ends with a single state.
      nv_phase = N*nx + N*ni + N*nu + N*np + N + nx;
      
      % number of variables in one control interval
      % + 1 for the timestep
      nci = nx+ni+nu+np+1;
      
      % Finds indizes of the variables in the NlpVars array.
      % cellfun is similar to python list comprehension 
      % e.g. [range(start_i,start_i+nx) for start_i in range(1,nv,nci)]
      X_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nx-1)', 1:nci:nv_phase, 'UniformOutput', false));
      I_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+ni-1)', nx+1:nci:nv_phase, 'UniformOutput', false));
      U_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nu-1)', nx+ni+1:nci:nv_phase, 'UniformOutput', false));
      P_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+np-1)', nx+ni+nu+1:nci:nv_phase, 'UniformOutput', false));
      H_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i)', nx+ni+nu+np+1:nci:nv_phase, 'UniformOutput', false));
      
      X = reshape(phaseVars(X_indizes), nx, N+1);
      I = reshape(phaseVars(I_indizes), ni, N);
      U = reshape(phaseVars(U_indizes), nu, N);
      P = reshape(phaseVars(P_indizes), np, N);
      H = reshape(phaseVars(H_indizes), 1 , N);
      
      % path constraints on first and last state
      pc0 = [];
      pc0_lb = [];
      pc0_ub = [];
      pcf = [];
      pcf_lb = [];
      pcf_ub = [];
      if options.path_constraints_at_boundary
        [pc0, pc0_lb, pc0_ub] = pathcon_fun(X(:,1), P(:,1));
        [pcf,pcf_lb,pcf_ub] = pathcon_fun(X(:,end), P(:,end));
      end         
      
      T0 = [0, cumsum(H(:,1:end-1))];
      
      [xend_arr, ~, cost_arr, int_eq_arr, int_times] = integrator_map(X(:,1:end-1), I, U, T0, H, P);
      [pc_eq_arr, pc_lb_arr, pc_ub_arr] = pathcon_map(X(:,2:end-1), P(:,2:end));
      
       % discrete path cost
      costD = pathcostd_map(X,P); 
                
      % timestep constraints
      h_eq = [];
      h_eq_lb = [];
      h_eq_ub = [];
      
      if isempty(T)      
        % h0 = h_1_hat / h_0_hat * h1 = h_2_hat / h_1_hat * h2 ...
        H_ratio = H_norm(1:end-1)./H_norm(2:end);
        h_eq = H_ratio .* H(:,2:end) - H(:,1:end-1);
        h_eq_lb = zeros(1, N-1);
        h_eq_ub = zeros(1, N-1);
      end
      
      % Parameter constraints 
      % p0=p1=p2=p3 ...
      p_eq = P(:,2:end)-P(:,1:end-1);
      p_eq_lb = zeros(np, N-1);
      p_eq_ub = zeros(np, N-1);
      
      % continuity (nx x N)
      continuity = xend_arr - X(:,2:end);
      
      % merge integrator equations, continuity, and path constraints,
      % timesteps constraints
      shooting_eq    = [int_eq_arr(:,1:N-1);   continuity(:,1:N-1);   pc_eq_arr;  h_eq;     p_eq];
      shooting_eq_lb = [zeros(ni,N-1);   zeros(nx,N-1);   pc_lb_arr;  h_eq_lb;  p_eq_lb];
      shooting_eq_ub = [zeros(ni,N-1);   zeros(nx,N-1);   pc_ub_arr;  h_eq_ub;  p_eq_ub];
      
      % reshape shooting equations to column vector, append final integrator and
      % continuity equations
      shooting_eq    = [shooting_eq(:);    int_eq_arr(:,N); continuity(:,N)];
      shooting_eq_lb = [shooting_eq_lb(:); zeros(ni,1);     zeros(nx,1)    ];
      shooting_eq_ub = [shooting_eq_ub(:); zeros(ni,1);     zeros(nx,1)    ];
      
      % collect all constraints
      constraints = vertcat(pc0, shooting_eq, pcf);
      constraints_LB = vertcat(pc0_lb, shooting_eq_lb, pcf_lb);
      constraints_UB = vertcat(pc0_ub, shooting_eq_ub, pcf_ub);
      
      % terminal cost
      costf = arrivalcost_fun(X(:,end),P(:,end));
      
      % sum all costs
      costs = sum(cost_arr) + costf + costD;
      
      % times
      times = [T0; int_times; T0];
      times = [times(:); T0(end)+H(end)];
      
      x0 = X(:,1);
      p0 = P(:,1);
      
    end % getNLPFun    
  end % methods
end % classdef

