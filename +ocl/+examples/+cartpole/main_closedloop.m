function t = main_closedloop

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


% control loop
log_str = ocl.utils.Reference([]);
t = timer('TimerFcn', @(t,d)loop(t,d,solver,log_window,log_str), 'ExecutionMode', 'fixedRate', 'Period', 1, 'UserData', []);
start(t);


end

function loop(~, ~, solver, log_window, log_str)

output_str = evalc('[sol,times] = solver.solve();');
log_str.set([log_str.get(), output_str]);

lines = splitlines(log_str.get());

set(log_window, 'String', lines);
drawnow
set(log_window, 'ListboxTop', numel(lines));

end