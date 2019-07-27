function pathcosts(ch,x,z,u,p)

ch.add(1e2*(x.p.'*x.p));
ch.add(1e2*(x.theta.'*x.theta));
ch.add(1e-2*(x.'*x));
ch.add(1e-2*u.'*u);