function handles = animateCartPole(sol,times,recordVideo)

  if nargin < 3
    recordVideo = false;
  end

  if recordVideo
    filename = ['Workspace/cartpole_', datestr(now,'yyyy-mm-dd_HHMMSS')];
    v = VideoWriter(filename);
    
    T = times.states.value;
    assert(all(T)==T(1));
    v.FrameRate = floor(1./(times.states(2).value-times.states(1).value));
    open(v);
  end

  pmax = max(abs(sol.states.p.value));
  [fig,handles] = create_fig(pmax);
  
  states = sol.states.value;
  times = times.states.value;
  times = times(:);
  
  for k=2:length(times)
    t = times(k);
    x = states(:,k);
    dt = t-times(k-1);
    draw(t, dt, x, handles);
    
    if recordVideo
      frame = getframe(fig);
      writeVideo(v, frame);
    end
  end
  
  if recordVideo
    close(v)
  end

end


function [fig,handles] = create_fig(pmax)
  
  fig = figure;
  set(fig,'Color','white')
  fig.OuterPosition = fig.InnerPosition;
  xticks(-5:5)
  yticks(-5:5)
  pbaspect([16 9 1])
  daspect([1 1 1])

  hold on;
  
  ms = 10;

  line([-pmax pmax], [0 0], 'color', 'k', 'Linewidth',1.5); hold on;
  line([-pmax -pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;
  line([pmax pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;

  h2 = text(-0.3,pmax, '0.00 s','FontSize',15);
  h3 = plot(0,0,'ks','MarkerSize',ms,'Linewidth',3);


  h4 = line(0, 0,'color',[38,124,185]/255,'Linewidth',2);
  h5 = plot(0,0,'o', 'color',[170,85,0]/255,'MarkerSize',ms,'Linewidth',3);

  grid on;
  ylim([-pmax pmax]);

  handles = {h2,h3,h4,h5};

  hold off;
  pause(1)
    
end

function draw(time, dt, x, handles)
  p = x(1);
  theta = x(2);
  t = time;
  l = 1.0;
  
  [h2,h3,h4,h5] = handles{:};

  xB = p+l*sin(theta);
  yB = l*cos(theta);

  set(h2, 'String', sprintf('%.2f s', t));

  set(h3, 'Xdata', p)

  set(h4,'Xdata',[p xB]);
  set(h4,'Ydata',[0 yB]);

  set(h5,'Xdata',xB);
  set(h5,'Ydata',yB); 

  global testRun
  if isempty(testRun) || (testRun==false)
    pause(dt);
  end
  
end



