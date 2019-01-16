function handles = visualizeCartPole(time, x, Xref, pmax, handles)

p = x.p.value;
theta = x.theta.value;
t = time.value;

l = 1.0;
ms = 10;

if isempty(handles)
  
  figure;
  whitebg([1.0 1.0 1.0])
  set(gcf,'Color',[1 1 1])

  hold on;
  x_r = Xref(1);
  y_r = 0;

  line([-pmax pmax], [0 0], 'color', 'k', 'Linewidth',1.5); hold on;
  line([-pmax -pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;
  line([pmax pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;

  h1 = plot(x_r, y_r, 'gx', 'MarkerSize', ms, 'Linewidth', 2);
  h2 = text(-0.3,pmax, '0.00 s','FontSize',15);
  h3 = plot(p,0,'ks','MarkerSize',ms,'Linewidth',3);

  xB = p-l*sin(theta);
  yB = l*cos(theta);

  h4 = line([p xB], [0 yB], 'Linewidth',2);
  h5 = plot(xB,yB,'ro','MarkerSize',ms,'Linewidth',3);

  grid on;
  xlim([-pmax-l pmax+l]);
  ylim([-pmax-l pmax+l]);
  
  handles = {h1,h2,h3,h4,h5};
  
  hold off;
  
else
  [h1,h2,h3,h4,h5] = handles{:};
  
  xB = p+l*sin(theta);
  yB = l*cos(theta);
  
  set(h2, 'String', sprintf('%.2f s', t));
  
  set(h3, 'Xdata', p)
  
  set(h4,'Xdata',[p xB]);
  set(h4,'Ydata',[0 yB]);
 
  set(h5,'Xdata',xB);
  set(h5,'Ydata',yB); 
end

