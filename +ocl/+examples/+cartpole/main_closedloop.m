function control_timer = main_closedloop

solver = ocl.Solver( ...
  3, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'terminalcost', @ocl.examples.cartpole.terminalcost, ...
  'N', 100, 'd', 3);

solver.setInitialState('p', 0);
solver.setInitialState('v', 0);
solver.setInitialState('theta', pi);
solver.setInitialState('omega', 0);

solver.initialize('theta', [0 1], [pi 0]);

% log window
log_fig = figure('menubar', 'none');
log_window = uicontrol(log_fig, 'Style', 'listbox', ...
  'Units',    'normalized', ...
  'Position', [0,0,1,1], ...
  'String',   {}, ...
  'Min', 0, 'Max', 2, ...
  'Value', []);

log_str = ocl.utils.Reference([]);

% control loop
control_timer = timer('TimerFcn', @(t,d) controller(t, d, solver, log_str), ...
  'ExecutionMode', 'fixedRate', 'Period', 1);

% logger loop
log_timer = timer('TimerFcn', @(t,d) logger(t, d, log_window, log_str), ...
  'ExecutionMode', 'fixedRate', 'Period', 1);

start(control_timer);
start(log_timer);

pause(5)

stop(control_timer)
stop(log_timer)

end

function controller(~, ~, solver, log_str)

output_str = evalc('[sol,times] = solver.solve();'); [~] = solver;

log_str.set([log_str.get(), output_str]);
end

function logger(~, ~, log_window, log_str)

lines = splitlines(log_str.get());
set(log_window, 'String', lines);
drawnow
set(log_window, 'ListboxTop', numel(lines));

end