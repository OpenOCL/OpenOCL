function main_closedloop
clear all;
close all;

T = 3;
N = 60;

solver = ocl.acados.Solver( ...
  T, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'terminalcost', @ocl.examples.cartpole.terminalcost, ...
  'N', N, 'verbose', false);

solver.setInitialState('p', 0);
solver.setInitialState('v', 0);
solver.setInitialState('theta', 0);
solver.setInitialState('omega', 0);

solver.initialize('theta', [0 1], [0 0]);

solver.solve();

x0 = [0;0;0;0];

sim = ocl.Simulator(@ocl.examples.cartpole.vars, @ocl.examples.cartpole.dae);
sim.reset(x0);

draw_handles = ocl.examples.cartpole.draw_prepare(x0(1), x0(2), 0.8, 6);

% log window
log_fig = figure('menubar', 'none');
log_window = uicontrol(log_fig, 'Style', 'listbox', ...
  'Units',    'normalized', ...
  'Position', [0,0,1,1], ...
  'String',   {}, ...
  'Min', 0, 'Max', 2, ...
  'Value', []);

data = struct;
data.T = T;
data.dt = T/N;
data.draw_handles = draw_handles;
data.t = 0;
data.current_state = x0;
data.force = 0;

% control loop
control_timer = timer('TimerFcn', @(t,d) controller(t, d, solver, sim, log_window), ...
  'ExecutionMode', 'fixedRate', 'Period', data.dt, 'UserData', data);

start(control_timer);
cli(control_timer);
stop(control_timer);

end

function controller(t, ~, solver, sim, log_window)

dt = t.UserData.dt;
draw_handles = t.UserData.draw_handles;
time = t.UserData.t;
current_state = t.UserData.current_state;
force = t.UserData.force;

solver.setInitialState('p', current_state(1));
solver.setInitialState('theta', current_state(2));
solver.setInitialState('v', current_state(3));
solver.setInitialState('omega', current_state(4));

[sol,~] = solver.solve();

u = sol.controls.F.value;

sim.current_state = current_state;

x = sim.step(u(1) + force, dt);
x = x.value;

if abs(x(1)) > 6
  sim.current_state = [0;0;0;0];
end

% draw
ocl.examples.cartpole.draw(draw_handles, time, x, 0.8);

lines = splitlines(solver.stats());
set(log_window, 'String', lines);
drawnow

t.UserData.sol = sol;
t.UserData.t = time + dt;
t.UserData.current_state = sim.current_state;
t.UserData.force = 0;

end

function cli(t)

  ocl.utils.info(['You are now in the command line interface. You can make use of ', ...
    'the following commands: q (quit), d (disturbance), f (force).']);

  terminated = false;
  while ~terminated
    m = input('  cli >>', 's');
    
    if strcmp(m, 'q') || strcmp(m, 'x') || strcmp(m, 'c')
      disp('exiting...')
      stop(t);
      terminated = true;
    elseif strcmp(m, 'd')
      disp('disturbance!')
      t.UserData.current_state = t.UserData.current_state + 1e-1 * (rand(4,1)-.5);
    elseif strcmp(m, 'f')
      disp('force!!')
      t.UserData.force = 30*sign(rand-0.5);
    elseif ~isempty(str2double(m))
      F = str2double(m);
      disp(['force ', m, '!!!']);
      t.UserData.force = F*sign(rand-0.5);
    end
  end

end