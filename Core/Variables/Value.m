classdef Value < handle
  % VALUE Class for storing values
  properties
    type
    positions
    val
  end
  methods
    function self = Value(type,positions,v)
      narginchk(3,3);
      self.type = type;
      self.positions = positions;
      self.val = v;
    end
    
    function r = numel(self)
      r = numel(self.positions);
    end
    
    function r = get(self,in1,in2)
      % r = get(self,id)
      % r = get(self,id,index)
      % r = get(self,index)
      % r = get(self,row,col)
      
      function t = isAllOperator(in)
        t = strcmp(in,'all') || strcmp(in,':');
        if t
          t = ':';
        end
      end
      
      if ischar(in1) && ~(isAllOperator(in1) || strcmp(in1,'end'))
        if nargin == 2
          % get(id)
          [t,p] = self.type.get(self.positions,in1);
          r = Value(t,p,self.val);
        else
          % get(id,selector)
          [t,p] = self.type.get(self.positions,in1);
          [t,p] = t.get(p,in2);
          r = Value(t,p,self.val);
        end
      else
        if nargin == 2
          % get(index)
          if isAllOperator(in1)
            r = self;
          else
            [t,p] = self.type.get(self.positions,in1);
            r = Value(t,p,self.val);
          end
        else
          % get(row,col)
          if isAllOperator(in1) && isAllOperator(in2)
            r = self;
          else
            [t,p] = self.type.get(self.positions,in1,in2);
            r = Value(t,p,self.val);
          end
        end
      end
    end
    
    function set(self,value,varargin)
      % set(value)
      % set(val,slice1,slice2,slice3)
      if nargin == 2
        self.val = value;
      else
        p = self.slice(varargin{:});
        self.val(p) = value;
      end
    end % set
    
    function vout = value(self,varargin)
      % value()
      % value(slice1,slice2,slice3)
      p = self.slice(varargin{:});
      vout = cell(1,length(p));
      for k=1:length(p)
        vout{k} = reshape(self.val(p{k}),size(p{k}));
      end
      if length(vout)==1
        vout = vout{1};
      end
    end
    
    function [pout,N,M,K] = slice(self,dim1,dim2,dim3)
      [pos,N,M,K] = self.type.getPositions(self.positions);
      
      if isnumeric(pos)
        pos = {pos};
      end
      assert(K==length(pos))
      
      pout = cell(1,K);
      for k=1:K
        p = reshape(pos{k},[N,M]);
        if nargin==2
          p = p(dim1);
        elseif nargin==3
          p = p(dim1,dim2);  
        end
        pout{k} = p;
      end
      if nargin==4
        pout = p(dim3);
      end
    end
  end
end

