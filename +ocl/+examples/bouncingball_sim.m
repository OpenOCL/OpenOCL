function [sol,times,solver] = bouncingball_sim(snap)

  % snap images for docs
  if nargin == 0
    snap = 0;
  end

  num_phases = 5;
  N = 10;
  
  phase0 = ocl.Phase([], @vars, @ode, 'N', N, 'd', 2);
  phase = ocl.Phase([], @vars, @ode, 'N', N, 'd', 2);

  phase0.setInitialStateBounds('s', 1);
  phase0.setInitialStateBounds('v', 0);
  
  phase0.setEndStateBounds('s', 0);
  phase.setEndStateBounds('s', 0);

  solver = OclSolver(num2cell([phase0,repmat(phase,1,num_phases-1)]), ...
                  repmat({@transition},1,num_phases-1));

  [sol,times] = solver.solve(solver.getInitialGuess());

  figure
  spy(full(solver.jacobian_pattern(sol)))
  
  vw = VideoWriter(fullfile(getenv('OPENOCL_WORK'),'bouncingball.avi'));
  vw.FrameRate = 30;
  open(vw)
  fig = figure; 
  h = plot(0,0,'o', 'Markersize', 20, 'MarkerEdgeColor','red', 'MarkerFaceColor',[1 .6 .6]);
  ylim([0 1])
  for k=1:num_phases
    % resample to 30 fps
    t = times{k}.states(1:end).value;
    s = sol{k}.states.s(1:end).value;
    t_new = linspace(0, max(t), 31);
    s_new = interp1(t,s,t_new);
    
    for j=2:length(s_new)
      tic;
      set(h, 'YData', s_new(j))
      
      frame = getframe(fig);
      writeVideo(vw,frame);
      
      if snap > 0 && mod(k,snap) == 0
        snapnow;
      end
      
      pause(t_new(j)-t_new(j-1)-toc)
    end
  end
  
  close(vw)

end

function vars(sh)
  sh.addState('s');
  sh.addState('v');
end

function ode(sh,x,~,~,~)
  sh.setODE('s', x.v);
  sh.setODE('v', -10);
end

function transition(ch, x0, xF)
  % x0 current phase
  % xF previous phase
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v/sqrt(2));
end


