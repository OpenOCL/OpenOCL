function run
  t = timer('TimerFcn', @loop, 'ExecutionMode', 'singleShot', 'Period', 1e-3, 'UserData', 1);
  start(t)
end

function loop(~, ~)
  disp('cou')
end