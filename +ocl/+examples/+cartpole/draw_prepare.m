function handles = draw_prepare(p, theta, l, pmax)

ms = 10; % marker size

figure;

hold on;

line([-pmax pmax], [0 0], 'color', 'k', 'Linewidth',1.5); hold on;
line([-pmax -pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;
line([pmax pmax], [-0.1 0.1], 'color', 'k', 'Linewidth',1.5); hold on;

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
pause(0.1)