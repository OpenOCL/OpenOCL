function oclStairs(x,y,varargin)
  x = OclTensor.getValue(x);
  y = OclTensor.getValue(y);
  
  stairs(x,y,'LineWidth', 3, varargin{:})
  