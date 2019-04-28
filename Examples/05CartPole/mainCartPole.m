function [sol,times,ocl] = mainCartPole  

  options = OclOptions();
  options.nlp.controlIntervals = 50;
  options.nlp.collocationOrder = 3;

  system = OclSystem('varsfun',@varsfun, 'eqfun', @eqfun);
  ocp = OclOCP('arrivalcosts', @arrivalcosts);
  
  ocl = OclSolver([], system, ocp, options);

  p0 = 0; v0 = 0;
  theta0 = 180*pi/180; omega0 = 0;

  ocl.setInitialBounds('p', p0);
  ocl.setInitialBounds('v', v0);
  ocl.setInitialBounds('theta', theta0);
  ocl.setInitialBounds('omega', omega0);
  
  ocl.setInitialBounds('time', 0);

  ocl.setEndBounds('p', 0);
  ocl.setEndBounds('v', 0);
  ocl.setEndBounds('theta', 0);
  ocl.setEndBounds('omega', 0);

  % Run solver to obtain solution
  [sol,times] = ocl.solve(ocl.ig());

  % visualize solution
  figure; hold on; grid on;
  oclStairs(times.controls, sol.controls.F/10.)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.p)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.v)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.theta)
  legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
  xlabel('time [s]');
  
  X = sol.states.value;
  P = sol.states.p.value;
  Theta = sol.states.theta.value;
  T = times.states.value;
  
  animData{1}.type = OclPlotTypes.plot;
  animData{1}.style = 'k';
  animData{1}.LineWidth = 1.5;
  animData{1}.Xdata = [-pmax pmax];
  animData{1}.Ydata = [0 0];
  
  animData{2}.type = OclPlotTypes.plot;
  animData{2}.style = 'k';
  animData{2}.LineWidth = 1.5;
  animData{2}.Xdata = [-pmax -pmax];
  animData{2}.Ydata = [0 0];
  
  animData{3}.type = OclPlotTypes.plot;
  animData{3}.style = 'k';
  animData{3}.LineWidth = 1.5;
  animData{3}.Xdata = [pmax pmax];
  animData{3}.Ydata = [-0.1 0.1];
  
  % time counter text
  animData{4}.type = OclPlotTypes.text;
  animData{4}.style = 'k';
  animData{4}.LineWidth = 1.5;
  animData{4}.Xdata = -0.3;
  animData{4}.Ydata = l+0.4;
  animData{4}.String = for_each(T, @(el) sprintf('%.2f s', el));
  animData{4}.FontSize = 15;
  
  % cart position
  animData{4}.type = OclPlotTypes.text;
  animData{4}.style = 'ks';
  animData{4}.LineWidth = 1.5;
  animData{4}.Xdata = X(1,:);
  animData{4}.MarkerSize = 10;
  
  % pole
  animData{4}.type = OclPlotTypes.text;
  animData{4}.color = [38,124,185]/255;
  animData{4}.LineWidth = 2;
  animData{4}.Xdata = for_each(zap(P, Theta), @(p,theta) [p, p-l*sin(theta)]);
  animData{4}.Ydata = for_each(zap(P, Theta), @(p,theta) [0, l*cos(theta)]);
  
  % bob
  animData{4}.type = OclPlotTypes.text;
  animData{4}.style = 'o';
  animData{4}.color = [170,85,0]/255;
  animData{4}.LineWidth = 3;
  animData{4}.Xdata = for_each(zap(P, Theta), @(p,theta) p-l*sin(theta) );
  animData{4}.Ydata = for_each(zap(P, Theta), @(p,theta) l*cos(theta) );
  animData{4}.MarkerSize = 10;
  
  
  oclAnimation()
  
  animateCartPole(sol,times);

end

function varsfun(sh)

  sh.addState('p', 'lb', -5, 'ub', 5);
  sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
  sh.addState('v');
  sh.addState('omega');
  
  sh.addState('time', 'lb', 0, 'ub', 20);

  sh.addControl('F', 'lb', -20, 'ub', 20);
end

function eqfun(sh,x,~,u,~)

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

function arrivalcosts(self,x,p)
  self.add( x.time );
end
