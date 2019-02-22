function oclPlot(x,y,varargin)
  x = OclTensor.getValue(x);
  y = OclTensor.getValue(y);
  
  plot(x,y,'LineWidth', 3, varargin{:})
  