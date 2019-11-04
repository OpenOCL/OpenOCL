function [sol,times,ocp] = bouncingball_sim

  num_stages = 5;
  N = 10;
  
  stage0 = ocl.Stage([], @vars, @ode, 'N', N, 'd', 2);
  stage = ocl.Stage([], @vars, @ode, 'N', N, 'd', 2);

  stage0.setInitialStateBounds('s', 1);
  stage0.setInitialStateBounds('v', 0);
  
  stage0.setEndStateBounds('s', 0);
  stage.setEndStateBounds('s', 0);

  ocp = ocl.MultiStageProblem(num2cell([stage0,repmat(stage,1,num_stages-1)]), ...
                      repmat({@transition},1,num_stages-1));

  [sol,times] = ocp.solve();


  vw = VideoWriter(fullfile(getenv('OPENOCL_WORK'),'bouncingball.avi'));
  vw.FrameRate = 30;
  open(vw)
  fig = figure; 
  h = plot(0,0,'o', 'Markersize', 20, 'MarkerEdgeColor','red', 'MarkerFaceColor',[1 .6 .6]);
  ylim([0 1])
  for k=1:num_stages
    % resample to 30 fps
    t = times{k}.states(1:end).value;
    s = sol{k}.states.s(1:end).value;
    t_new = linspace(0, max(t), 31);
    s_new = interp1(t,s,t_new);
    
    snap_at = floor(linspace(2,length(s_new),4));
    
    for j=2:length(s_new)
      tic;
      set(h, 'YData', s_new(j))
      
      frame = getframe(fig);
      writeVideo(vw,frame);
      
      % record image for docs
      if k == snap_at(1)
        snapnow;
        snap_at = snap_at(2:end);
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
  % x0 current stage
  % xF previous stage
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v/sqrt(2));
end


