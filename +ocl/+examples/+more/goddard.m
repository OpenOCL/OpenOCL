% Problem formulation from
%   https://www.bocop.org/goddard/
%

function goddard

  conf = struct;
  conf.b = 7;
  conf.Tmax = 3.5;
  conf.A = 310;
  conf.k = 500;
  conf.r0 = 1;

  ocp = ocl.Problem([], ...
    @vars, ...
    @(h,x,z,u,p) dynamics(h,x,z,u,p,conf), ...
    'gridconstraints', @(h,k,K,x,p) gridconstraints(h,k,K,x,p,conf), ...
    'terminalcost', @terminalcost, ...
    'N', 200, 'd', 3);
  
  ocp.setBounds('u', 0, 1);
  
  ocp.setInitialState('r', 1);
  ocp.setInitialState('v', 0);
  ocp.setInitialState('m', 1);
  
  ocp.setEndBounds('r', 1.01);
  
  figure;
  C_list = {0.8, 0.65, 0.5};
  for k=1:length(C_list)
    C = C_list{k};
    ocp.setParameter('C', C);
    
    [sol, times] = ocp.solve(ocp.ig());

    v = sol.states.v.value;
    r = sol.states.r.value;
    rho = exp(-conf.k * (r-conf.r0));
    D = conf.A * v.^2 .* rho;

    subplot(1, 2, 1); hold on;
    ocl.plot(times.controls, sol.controls);
    
    subplot(1, 2, 2); hold on;
    ocl.plot(times.states, D - C);
    
  end
  
  subplot(1, 2, 1); hold on;
  xlabel('TIME')
  ylabel('CONTROL')
  legend({'C=0.8', 'C=0.65', 'C=0.5'});

  subplot(1, 2, 2); hold on;
  xlabel('TIME')
  ylabel('DRAG-C')
  legend({'C=0.8', 'C=0.65', 'C=0.5'});
  
end

function vars(h)

  h.addState('r');
  h.addState('v');
  h.addState('m');

  h.addControl('u');
  
  h.addParameter('C');

end

function dynamics(h, x, z, u, p, conf)

  b = conf.b;
  Tmax = conf.Tmax;
  A = conf.A;
  k = conf.k;
  r0 = conf.r0;

  r = x.r;
  v = x.v;
  m = x.m;

  rho = exp(-k * (r-r0));
  D = A*v^2*rho;

  h.setODE('r', v);
  h.setODE('v', -1/r^2 + 1/m * (Tmax * u - D));
  h.setODE('m', -b*u);

end

function gridconstraints(h, k, K, x, p, conf)

  A = conf.A;
  k = conf.k;
  r0 = conf.r0;
  
  r = x.r;
  v = x.v;
  
  rho = exp(-k * (r-r0));
  D = A * v^2 * rho;
  
  h.add(D, '<=', p.C);
end

function terminalcost(h, x, p)
  h.add(-x.m);
end




