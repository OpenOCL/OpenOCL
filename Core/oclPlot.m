function oclPlot(x,y,varargin)
  x = Variable.getValue(x);
  y = Variable.getValue(y);
  
  plot(x,y,'LineWidth', 5, varargin{:})
  hold off
  