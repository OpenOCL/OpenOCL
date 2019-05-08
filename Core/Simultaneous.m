classdef Simultaneous < handle
  %SIMULTANEOUS Direct collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties (Constant)
    h_min = 0.001;
  end
  
  methods (Static)
    
    function varsStruct = vars(phaseList)
      
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
        phaseStruct.add('parameters', phase.parameters);

        varsStruct.add('phases', phaseStruct);
      end
      if length(phaseList) == 1
        varsStruct = phaseStruct;
      end
    end
    
    function timesStruct = times(nit, N)
      timesStruct = OclStructure();
      timesStruct.addRepeated({'states', 'integrator', 'controls'}, ...
                                   {OclMatrix([1,1]), OclMatrix([nit,1]), OclMatrix([1,1])}, N);
      timesStruct.add('states', OclMatrix([1,1]));
    end
    
    
    function ig = ig(self)
      ig = self.getInitialGuess();
    end
    
    function guess = igFromBounds(bounds)
      % Averages the bounds to get an initial guess value.
      % Makes sure no nan values are produced, defaults to 0.
      
      lowVal  = bounds.lower;
      upVal   = bounds.upper;
      
      guess = (lowVal + upVal) / 2;
      
      % set to lowerBounds if upperBounds are inf
      indizes = isinf(upVal);
      guess(indizes) = lowVal(indizes);
      
      % set to upperBounds of lowerBoudns are inf
      indizes = isinf(lowVal);
      guess(indizes) = upVal(indizes);
      
      % set to zero if both lower and upper bounds are inf
      indizes = isinf(lowVal) & isinf(upVal);
      guess(indizes) = 0;
      
    end
    
    function [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = getPhaseIndizes(phase, N)

      nx = phase.nx;
      ni = phase.integrator.ni;
      nu = phase.nu;
      np = phase.np;
      
      % number of variables in one control interval
      % + 1 for the timestep
      nci = nx+ni+nu+np+1;

      % Finds indizes of the variables in the NlpVars array.
      % cellfun is similar to python list comprehension 
      % e.g. [range(start_i,start_i+nx) for start_i in range(1,nv,nci)]
      X_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nx-1)', (0:N)*nci+1, 'UniformOutput', false));
      I_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+ni-1)', (0:N-1)*nci+nx+1, 'UniformOutput', false));
      U_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nu-1)', (0:N-1)*nci+nx+ni+1, 'UniformOutput', false));
      
      p_start = [(0:N-1)*nci+nx+ni+nu+1, (N)*nci+nx+1];
      P_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+np-1)', p_start, 'UniformOutput', false));
      H_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i)', (0:N-1)*nci+nx+ni+nu+np+1, 'UniformOutput', false));
    end
    
    function bounds = mergeLowerBounds(oldBounds, newBounds)

      bounds = max(oldBounds, newBounds);
    end
        
    function [lowerBounds,upperBounds] = getNlpBounds(phaseList)
      
      lowerBounds = cell(length(phaseList), 1);
      upperBounds = cell(length(phaseList), 1);
      
      for k=1:length(phaseList)
        
        phase = phaseList{k};
        [nv_phase,N] = Simultaneous.nvars(phase.H_norm, phase.nx, phase.integrator.ni, phase.nu, phase.np);
        
        lb_phase = -inf * ones(nv_phase,1);
        ub_phase = inf * ones(nv_phase,1);

        [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getPhaseIndizes(phase, N);
        
        % states
        for m=1:size(X_indizes,2)
          lb_phase(X_indizes(:,m)) = phase.stateBounds.lower;
          ub_phase(X_indizes(:,m)) = phase.stateBounds.upper;
        end
        
        % Merge the two vectors of bound values for lower bounds and upper bounds.
        % Bound values can only get narrower, e.g. higher for lower bounds.
        lb_phase(X_indizes(:,1)) = max(phase.stateBounds.lower,phase.stateBounds0.lower);
        ub_phase(X_indizes(:,1)) = min(phase.stateBounds.upper,phase.stateBounds0.upper);
        
        lb_phase(X_indizes(:,end)) = max(phase.stateBounds.lower,phase.stateBoundsF.lower);
        ub_phase(X_indizes(:,end)) = min(phase.stateBounds.upper,phase.stateBoundsF.upper);
        
        % integrator bounds
        for m=1:size(I_indizes,2)
          lb_phase(I_indizes(:,m)) = phase.integrator.integratorBounds.lower;
          ub_phase(I_indizes(:,m)) = phase.integrator.integratorBounds.upper;
        end
        
        % controls
        for m=1:size(U_indizes,2)
          lb_phase(U_indizes(:,m)) = phase.controlBounds.lower;
          ub_phase(U_indizes(:,m)) = phase.controlBounds.upper;
        end
        
        % parameters (only set the initial parameters)
        lb_phase(P_indizes(:,1)) = phase.parameterBounds.lower;
        ub_phase(P_indizes(:,1)) = phase.parameterBounds.upper;
        
        % timesteps
        if isempty(phase.T)
          lb_phase(H_indizes) = Simultaneous.h_min;
        else
          lb_phase(H_indizes) = phase.H_norm * phase.T;
          ub_phase(H_indizes) = phase.H_norm * phase.T;
        end
        lowerBounds{k} = lb_phase;
        upperBounds{k} = ub_phase;
      end
      lowerBounds = vertcat(lowerBounds{:});
      upperBounds = vertcat(upperBounds{:});
      
    end
    
    function ig = getInitialGuess(phaseList)
      % creates an initial guess from the information that we have about
      % bounds, phases etc.
      
      ig = cell(length(phaseList), 1);
      
      for k=1:length(phaseList)
        
        phase = phaseList{k};
        [nv_phase,N] = Simultaneous.nvars(phase.H_norm, phase.nx, phase.integrator.ni, phase.nu, phase.np);

        [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getPhaseIndizes(phase, N);
        
        ig_phase = 0 * ones(nv_phase,1);
        
        % states
        for m=1:size(X_indizes,2)
          ig_phase(X_indizes(:,m)) = Simultaneous.igFromBounds(phase.stateBounds);
        end
        
        ig_phase(X_indizes(:,1)) = Simultaneous.igFromBounds(phase.stateBounds0);
        ig_phase(X_indizes(:,end)) = Simultaneous.igFromBounds(phase.stateBoundsF);
        
        % integrator bounds
        for m=1:size(I_indizes,2)
          ig_phase(I_indizes(:,m)) = Simultaneous.igFromBounds(phase.integrator.integratorBounds);
        end
        
        % controls
        for m=1:size(U_indizes,2)
          ig_phase(U_indizes(:,m)) = Simultaneous.igFromBounds(phase.controlBounds);
        end
        
        % parameters
        for m=1:size(P_indizes,2)
          ig_phase(P_indizes(:,m)) = Simultaneous.igFromBounds(phase.parameterBounds);
        end
        
        % timesteps
        if isempty(phase.T)
          ig_phase(H_indizes) = phase.H_norm;
        else
          ig_phase(H_indizes) = phase.H_norm * phase.T;
        end
        ig{k} = ig_phase;
        
      end
      ig = vertcat(ig{:});
    end
    
    function [nv_phase,N] = nvars(H_norm, nx, ni, nu, np)
      % number of control intervals
      N = length(H_norm);
      
      % N control interval which each have states, integrator vars,
      % controls, parameters, and timesteps.
      % Ends with a single state.
      nv_phase = N*nx + N*ni + N*nu + N*np + N + nx + np;
    end
    
    function [costs,constraints,constraints_lb,constraints_ub,times,x0,p0] = simultaneous(phase, phaseVars)
      
      H_norm = phase.H_norm;
      T = phase.T;
      nx = phase.nx;
      ni = phase.integrator.ni;
      nu = phase.nu;
      np = phase.np;
      pathcost_fun = @phase.pathcostfun;
      pathcon_fun = @phase.pathconfun;

      [nvars,N] = Simultaneous.nvars(H_norm, nx, ni, nu, np);
      [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getPhaseIndizes(phase, N);
      
      X = reshape(phaseVars(X_indizes), nx, N+1);
      I = reshape(phaseVars(I_indizes), ni, N);
      U = reshape(phaseVars(U_indizes), nu, N);
      P = reshape(phaseVars(P_indizes), np, N+1);
      H = reshape(phaseVars(H_indizes), 1 , N);
      
      % path constraints
      pcon = cell(1,N+1);
      pcon_lb = cell(1,N+1);
      pcon_ub = cell(1,N+1);
      pcost = 0;
      for k=1:N+1
        [pcon{k}, pcon_lb{k}, pcon_ub{k}] = pathcon_fun(k, N, X(:,k), P(:,k));
        pcost = pcost + pathcost_fun(k, N, X(:,k), P(:,k));
      end    
      
      pcon = horzcat(pcon{:});
      pcon_lb = horzcat(pcon_lb{:});
      pcon_ub = horzcat(pcon_ub{:});
      
      % fix dimensions of empty path constraints
      if isempty(pcon)
        pcon = double.empty(0,N+1);
        pcon_lb = double.empty(0,N+1);
        pcon_ub = double.empty(0,N+1);
      end
      
      [xend_arr, cost_arr, int_eq_arr, int_times] = phase.integratormap(X(:,1:end-1), I, U, H, P(:,1:end-1));
                
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
      p_eq_lb = zeros(np, N);
      p_eq_ub = zeros(np, N);
      
      % continuity (nx x N)
      continuity = xend_arr - X(:,2:end);
      
      % merge integrator equations, continuity, and path constraints,
      % timesteps constraints
      shooting_eq    = [int_eq_arr(:,1:N-1);   continuity(:,1:N-1);   pcon(:,2:N);     h_eq;     p_eq(:,1:N-1)];
      shooting_eq_lb = [zeros(ni,N-1);         zeros(nx,N-1);         pcon_lb(:,2:N);  h_eq_lb;  p_eq_lb(:,1:N-1)];
      shooting_eq_ub = [zeros(ni,N-1);         zeros(nx,N-1);         pcon_ub(:,2:N);  h_eq_ub;  p_eq_ub(:,1:N-1)];
      
      % reshape shooting equations to column vector, append lastintegrator and
      % continuity equations
      constraints    = [pcon(:,1);      shooting_eq(:);    int_eq_arr(:,N); continuity(:,N); pcon(:,N+1);       p_eq(:,N)    ];
      constraints_lb = [pcon_lb(:,1);   shooting_eq_lb(:); zeros(ni,1);     zeros(nx,1);     pcon_lb(:,N+1);    p_eq_lb(:,N) ];
      constraints_ub = [pcon_ub(:,1);   shooting_eq_ub(:); zeros(ni,1);     zeros(nx,1);     pcon_ub(:,N+1);    p_eq_ub(:,N) ];

      % sum all costs
      costs = sum(cost_arr) + pcost;
      
      % times output
      T0 = [0, cumsum(H(:,1:end-1))];
      for k=1:size(int_times,1)
        int_times(k,:) = T0 + int_times(k,:);
      end
      times = [T0; int_times; T0];
      times = [times(:); T0(end)+H(end)];
      
      x0 = X(:,1);
      p0 = P(:,1);
      
    end % getNLPFun    
  end % methods
end % classdef

