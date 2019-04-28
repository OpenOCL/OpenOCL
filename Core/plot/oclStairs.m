function h = oclStairs(x,y,varargin)
  x = Variable.getValue(x);
  y = Variable.getValue(y);
  
  % set stronger default Linewidth if not set
  if ~isempty(find(strcmp(varargin, 'Linewidth'), 1))
    varargin{end+1} = 'Linewidth';
    varargin{end+1} = 3;
  end
  
  h = stairs(x, y, varargin{:});
  