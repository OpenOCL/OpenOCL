% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [sol,times,ocp] = cartpole

  ocp = ocl.Problem([], 'vars', @varsfun, 'dae', @daefun, ...
    'terminalcost', @terminalcost, 'N', 40, 'd', 3);

  p0 = 0; v0 = 0;
  theta0 = 180*pi/180; omega0 = 0;

  ocp.setInitialBounds('p', p0);
  ocp.setInitialBounds('v', v0);
  ocp.setInitialBounds('theta', theta0);
  ocp.setInitialBounds('omega', omega0);
  
  ocp.setInitialBounds('time', 0);

  ocp.setEndBounds('p', 0);
  ocp.setEndBounds('v', 0);
  ocp.setEndBounds('theta', 0);
  ocp.setEndBounds('omega', 0);
  
  ocp.setEndBounds('time',     1.25, 2);
  
  ocp.initialize('theta', [0 1], [pi 0]);
  ocp.initialize('F', [0 1], [1 1]);

  % Run solver to obtain solution
  [sol,times] = ocp.solve();

  % visualize solution
  figure; hold on; grid on;
  ocl.stairs(times.controls, sol.controls.F/10.)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.p)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.v)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.theta)
  legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
  xlabel('time [s]');

  animate(sol,times);

end

function varsfun(sh)

  sh.addState('p', 'lb', -5, 'ub', 5);
  sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
  sh.addState('v');
  sh.addState('omega');
  
  sh.addState('time', 'lb', 0, 'ub', 10);

  sh.addControl('F', 'lb', -12, 'ub', 12);
end

function daefun(sh,x,~,u,~)

  g = 9.8;
  cm = 1.0;
  pm = 0.1;
  phl = 0.5; % pole half length

  m = cm+pm;
  pml = pm*phl; % pole mass length

  ctheta = cos(x.theta);
  stheta = sin(x.theta);

  domega = (g*stheta + ...
            ctheta * (-u.F-pml*x.omega^2*stheta) / m) / ...
            (phl * (4.0 / 3.0 - pm * ctheta^2 / m));

  a = (u.F + pml*(x.omega^2*stheta-domega*ctheta)) / m;

  sh.setODE('p',x.v);
  sh.setODE('theta',x.omega);
  sh.setODE('v',a);
  sh.setODE('omega',domega);
  
  sh.setODE('time', 1);
  
end

function terminalcost(ocl,x,~)
  ocl.add( x.time );
end

function handles = animate(sol,times)

  handles = {};
  pmax = max(abs(sol.states.p.value));
  
  states = sol.states.value;
  times = times.states.value;
  times = times(:);
  
  snap_at = floor(linspace(2,length(times),4));
  
  for k=2:length(times)
    t = times(k);
    x = states(:,k);
    dt = t-times(k-1);
    
    handles = draw(t, dt, x, [0,0,0,0], pmax, handles);
    
    % record image for docs
    if k == snap_at(1)
      snapnow;
      snap_at = snap_at(2:end);
    end
  end
end

function handles = draw(time, dt, x, Xref, pmax, handles)
  p = x(1);
  theta = x(2);
  t = time;

  l = 1.0;
  ms = 10;

  if isempty(handles)
  
    figure;

    hold on;
    x_target = Xref(1);
    y_target = 0;

    line([-pmax pmax], [0 0], 'color', 'k', 'Linewidth',1.5); hold on;
    line([-pmax -pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;
    line([pmax pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;

    plot(x_target, y_target, 'x', 'color', [38,124,185]/255, 'MarkerSize', ms, 'Linewidth', 2);
    h2 = text(-0.3,pmax, '0.00 s','FontSize',15);
    h3 = plot(p,0,'ks','MarkerSize',ms,'Linewidth',3);

    xB = p+l*sin(theta);
    yB = l*cos(theta);

    h4 = line([p xB], [0 yB],'color',[38,124,185]/255,'Linewidth',2);
    h5 = plot(xB,yB,'o', 'color',[170,85,0]/255,'MarkerSize',ms,'Linewidth',3);

    grid on;
    xlim([-pmax-l pmax+l]);
    ylim([-pmax-l pmax+l]);

    handles = {h2,h3,h4,h5};

    hold off;
    pause(1)

  else
    [h2,h3,h4,h5] = handles{:};

    xB = p+l*sin(theta);
    yB = l*cos(theta);

    set(h2, 'String', sprintf('%.2f s', t));

    set(h3, 'Xdata', p)

    set(h4,'Xdata',[p xB]);
    set(h4,'Ydata',[0 yB]);

    set(h5,'Xdata',xB);
    set(h5,'Ydata',yB); 
  end

  global testRun
  if isempty(testRun) || (testRun==false)
    pause(dt);
  end
end



