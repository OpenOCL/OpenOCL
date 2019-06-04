% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Simultaneous < handle
  %SIMULTANEOUS Direct collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties (Constant)
    h_min = 0.001;
  end
  
  methods (Static)
    
    function phase_vars_structure = vars(stage)
      
      phase_vars_structure = OclStructure();
      phase_vars_structure.addRepeated({'states','integrator','controls','parameters','h'}, ...
                          {stage.states, ...
                           stage.integrator.vars, ...
                           stage.controls, ...
                           stage.parameters, ...
                           OclMatrix([1,1])}, length(stage.H_norm));
      phase_vars_structure.add('states', stage.states);
      phase_vars_structure.add('parameters', stage.parameters);
    end
    
    function phase_time_struct = times(stage)
      phase_time_struct = OclStructure();
      phase_time_struct.addRepeated({'states', 'integrator', 'controls'}, ...
                              {OclMatrix([1,1]), OclMatrix([stage.integrator.nt,1]), OclMatrix([1,1])}, length(stage.H_norm));
      phase_time_struct.add('states', OclMatrix([1,1]));
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
    
    function x = first_state(stage,stageVars)
      [X_indizes, ~, ~, ~, ~] = Simultaneous.getPhaseIndizes(stage);
      x = stageVars(X_indizes(:,1));
    end
    
    function x = last_state(stage,stageVars)
      [X_indizes, ~, ~, ~, ~] = Simultaneous.getPhaseIndizes(stage);
      x = stageVars(X_indizes(:,end));
    end
    
    function [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = getStageIndizes(stage)

      N = length(stage.H_norm);
      nx = stage.nx;
      ni = stage.integrator.ni;
      nu = stage.nu;
      np = stage.np;
      
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
        
    function [lb_stage,ub_stage] = getBounds(stage)
      
      [nv_stage,~] = Simultaneous.nvars(stage.H_norm, stage.nx, stage.integrator.ni, stage.nu, stage.np);

      lb_stage = -inf * ones(nv_stage,1);
      ub_stage = inf * ones(nv_stage,1);

      [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getStageIndizes(stage);

      % states
      for m=1:size(X_indizes,2)
        lb_stage(X_indizes(:,m)) = stage.stateBounds.lower;
        ub_stage(X_indizes(:,m)) = stage.stateBounds.upper;
      end

      % Merge the two vectors of bound values for lower bounds and upper bounds.
      % Bound values can only get narrower, e.g. higher for lower bounds.
      lb_stage(X_indizes(:,1)) = max(stage.stateBounds.lower,stage.stateBounds0.lower);
      ub_stage(X_indizes(:,1)) = min(stage.stateBounds.upper,stage.stateBounds0.upper);

      lb_stage(X_indizes(:,end)) = max(stage.stateBounds.lower,stage.stateBoundsF.lower);
      ub_stage(X_indizes(:,end)) = min(stage.stateBounds.upper,stage.stateBoundsF.upper);

      % integrator bounds
      for m=1:size(I_indizes,2)
        lb_stage(I_indizes(:,m)) = stage.integrator.integratorBounds.lower;
        ub_stage(I_indizes(:,m)) = stage.integrator.integratorBounds.upper;
      end

      % controls
      for m=1:size(U_indizes,2)
        lb_stage(U_indizes(:,m)) = stage.controlBounds.lower;
        ub_stage(U_indizes(:,m)) = stage.controlBounds.upper;
      end

      % parameters (only set the initial parameters)
      lb_stage(P_indizes(:,1)) = stage.parameterBounds.lower;
      ub_stage(P_indizes(:,1)) = stage.parameterBounds.upper;

      % timesteps
      if isempty(stage.T)
        lb_stage(H_indizes) = Simultaneous.h_min;
      else
        lb_stage(H_indizes) = stage.H_norm * stage.T;
        ub_stage(H_indizes) = stage.H_norm * stage.T;
      end
    end
    
    function ig_stage = getInitialGuess(stage)
      % creates an initial guess from the information that we have about
      % bounds in the phase
      
      [nv_phase,N] = Simultaneous.nvars(stage.H_norm, stage.nx, stage.integrator.ni, stage.nu, stage.np);

      [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getStageIndizes(stage);

      ig_stage = 0 * ones(nv_phase,1);

      igx0 = Simultaneous.igFromBounds(stage.stateBounds0);
      igxF = Simultaneous.igFromBounds(stage.stateBoundsF);

      ig_stage(X_indizes(:,1)) = igx0;
      ig_stage(X_indizes(:,end)) = igxF;

      algVarsGuess = Simultaneous.igFromBounds(stage.integrator.algvarBounds);      
      for m=1:N
        xGuessInterp = igx0 + (m-1)/N.*(igxF-igx0);
        % integrator variables
        ig_stage(I_indizes(:,m)) = stage.integrator.getInitialGuess(xGuessInterp, algVarsGuess);

        % states
        ig_stage(X_indizes(:,m)) = xGuessInterp;
      end

      % controls
      for m=1:size(U_indizes,2)
        ig_stage(U_indizes(:,m)) = Simultaneous.igFromBounds(stage.controlBounds);
      end

      % parameters
      for m=1:size(P_indizes,2)
        ig_stage(P_indizes(:,m)) = Simultaneous.igFromBounds(stage.parameterBounds);
      end

      % timesteps
      if isempty(stage.T)
        ig_stage(H_indizes) = stage.H_norm;
      else
        ig_stage(H_indizes) = stage.H_norm * stage.T;
      end
    end
    
    function [nv_stage,N] = nvars(H_norm, nx, ni, nu, np)
      % number of control intervals
      N = length(H_norm);
      
      % N control interval which each have states, integrator vars,
      % controls, parameters, and timesteps.
      % Ends with a single state.
      nv_stage = N*nx + N*ni + N*nu + N*np + N + nx + np;
    end
    
    function [costs,constraints,constraints_lb,constraints_ub,times,x0,p0] = simultaneous(stage, stage_vars, ...
            controls_regularization, controls_regularization_value)
      
      H_norm = stage.H_norm;
      T = stage.T;
      nx = stage.nx;
      ni = stage.integrator.ni;
      nu = stage.nu;
      np = stage.np;
      pointcost_fun = @stage.pointcostfun;
      pointcon_fun = @stage.pointconstraintfun;

      [~,N] = Simultaneous.nvars(H_norm, nx, ni, nu, np);
      [X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getStageIndizes(stage);
      
      X = reshape(stage_vars(X_indizes), nx, N+1);
      I = reshape(stage_vars(I_indizes), ni, N);
      U = reshape(stage_vars(U_indizes), nu, N);
      P = reshape(stage_vars(P_indizes), np, N+1);
      H = reshape(stage_vars(H_indizes), 1 , N);
      
      % point constraints, point costs
      pointcon = cell(1,N+1);
      pointcon_lb = cell(1,N+1);
      pointcon_ub = cell(1,N+1);
      pointcost = 0;
      for k=1:N+1
        [pointcon{k}, pointcon_lb{k}, pointcon_ub{k}] = pointcon_fun(k, N+1, X(:,k), P(:,k));
        pointcost = pointcost + pointcost_fun(k, N+1, X(:,k), P(:,k));
      end    
      
      pointcon = horzcat(pointcon{:});
      pointcon_lb = horzcat(pointcon_lb{:});
      pointcon_ub = horzcat(pointcon_ub{:});
      
      % fix dimensions of empty path constraints
      if isempty(pointcon)
        pointcon = double.empty(0,N+1);
        pointcon_lb = double.empty(0,N+1);
        pointcon_ub = double.empty(0,N+1);
      end
      
      [xend_arr, cost_arr, int_eq_arr, int_times] = stage.integratormap(X(:,1:end-1), I, U, H, P(:,1:end-1));
                
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
      shooting_eq    = [int_eq_arr(:,1:N-1);   continuity(:,1:N-1);   pointcon(:,2:N);     h_eq;     p_eq(:,1:N-1)];
      shooting_eq_lb = [zeros(ni,N-1);         zeros(nx,N-1);         pointcon_lb(:,2:N);  h_eq_lb;  p_eq_lb(:,1:N-1)];
      shooting_eq_ub = [zeros(ni,N-1);         zeros(nx,N-1);         pointcon_ub(:,2:N);  h_eq_ub;  p_eq_ub(:,1:N-1)];
      
      % reshape shooting equations to column vector, append lastintegrator and
      % continuity equations
      constraints    = [pointcon(:,1);      shooting_eq(:);    int_eq_arr(:,N); continuity(:,N); pointcon(:,N+1);       p_eq(:,N)    ];
      constraints_lb = [pointcon_lb(:,1);   shooting_eq_lb(:); zeros(ni,1);     zeros(nx,1);     pointcon_lb(:,N+1);    p_eq_lb(:,N) ];
      constraints_ub = [pointcon_ub(:,1);   shooting_eq_ub(:); zeros(ni,1);     zeros(nx,1);     pointcon_ub(:,N+1);    p_eq_ub(:,N) ];

      % sum all costs
      costs = sum(cost_arr) + pointcost;
      
      % regularization on U
      if controls_regularization && numel(U)>0
        Uvec = U(:);
        costs = costs + controls_regularization_value*(Uvec'*Uvec);
      end
      
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

