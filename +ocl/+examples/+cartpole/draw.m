function draw(handles, time, x, l)
p = x(1);
theta = x(2);
t = time;

[h2,h3,h4,h5] = handles{:};

xB = p-l*sin(theta);
yB = l*cos(theta);

set(h2, 'String', sprintf('%.2f s', t));

set(h3, 'Xdata', p)

set(h4,'Xdata',[p xB]);
set(h4,'Ydata',[0 yB]);

set(h5,'Xdata',xB);
set(h5,'Ydata',yB); 
