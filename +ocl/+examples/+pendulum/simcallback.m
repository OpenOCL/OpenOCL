function simcallback(x,~,~,t0,t1,param)
  p = x.p.value;
  l = param.l.value;
  dt = t1-t0;

  plot(0,0,'ob', 'MarkerSize', 22)
  hold on
  plot([0,p(1)],[0,p(2)],'-k', 'LineWidth', 4)
  plot(p(1),p(2),'ok', 'MarkerSize', 22, 'MarkerFaceColor','r')
  xlim([-l,l])
  ylim([-l,l])

  pause(dt.value);
  hold off
end