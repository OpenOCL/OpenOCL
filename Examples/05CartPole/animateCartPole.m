function handles = animateCartPole(sol,times)

  handles = {};
  pmax = max(abs(sol.states.p.value));
  for k=2:prod(times.integrator.size)
    t = times.integrator(k).value;
    p = sol.integrator.states.p(:,:,k).value;
    theta = sol.integrator.states.theta(:,:,k).value;
    dt = times.integrator(k)-times.integrator(k-1);
    handles = draw(t, dt.value, p, theta, [0,0,0,0], pmax, handles);
  end

end

function handles = draw(t, dt, p, theta, Xref, pmax, handles)

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

    xB = p-l*sin(theta);
    yB = l*cos(theta);

    h4 = line([p xB], [0 yB],'color',[38,124,185]/255,'Linewidth',2);
    h5 = plot(xB,yB,'o', 'color',[170,85,0]/255,'MarkerSize',ms,'Linewidth',3);

    grid on;
    xlim([-pmax-l pmax+l]);
    ylim([-pmax-l pmax+l]);

    handles = {h2,h3,h4,h5};

    hold off;

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



