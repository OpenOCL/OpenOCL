function oclStairs(x,y,varargin)
  x = Variable.getValue(x);
  y = Variable.getValue(y);
  
  stairs(x,y,'LineWidth', 3, varargin{:})
  