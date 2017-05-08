classdef Arithmetic < handle
  
  properties
    thisValue
  end
  
  methods
    
    function self = Arithmetic(v)
      if nargin == 1
        self.setValue(v);
      end
    end
    
    function v = horzcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        val = varargin{k};
        if isa(val,'Arithmetic')
          inValues{k} = val.value;
        else
          inValues{k} = val;
        end
      end    
      v = Arithmetic(horzcat(inValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        val = varargin{k};
        if isa(val,'Arithmetic')
          inValues{k} = val.value;
        else
          inValues{k} = val;
        end
      end
      v = Arithmetic(vertcat(inValues{:}));
    end
    
    function varargout = subsref(self,s)
      if numel(s) == 1 && strcmp(s.type,'()')
        [varargout{1}] = Arithmetic(self.value.subsref(s));
      elseif numel(s) > 1 && strcmp(s(1).type,'()')
        v = Arithmetic(self.value.subsref(s(1)));
        [varargout{1:nargout}] = subsref(v,s(2:end));
      else
        [varargout{1:nargout}] = builtin('subsref',self,s);
      end
    end
    
    function self = subsasgn(self,s,v)
      if numel(s)==1 && strcmp(s.type,'()')
        v = subsasgn(self.value,s,v);
        self.setValue(v);
      else
        self.setValue(builtin('subsasgn',self.value,s,v));
      end
    end
    
    function v = mtimes(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(mtimes(a,b));
    end
   
    function v = ctranspose(self)
      % There is no complex transpose with casadi, so we call matrix
      % transpose.
      v = transpose(self);
    end
    function v = transpose(self)
      v = Arithmetic(transpose(self.value));
    end
    
    function v = reshape(self,varargin)
      v = Arithmetic(reshape(self.value,varargin{:}));
    end
    
    function v = triu(self)
      v = Arithmetic(triu(self.value));
    end
    
    function v = repmat(self,varargin)
      v = Arithmetic(repmat(self.value,varargin{:}));
    end
    
    function v = sum(a)
      v = Arithmetic(sum(a.value));
    end
    
    function v = norm(a,varargin)
      v = Arithmetic(norm(a.value,varargin{:}));
    end
    
    function v = mpower(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(mpower(a,b));
    end
    
    function v = mrdivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(mrdivide(a,b));
    end
    
    function v = mldivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      if (numel(a) > 1) && (numel(b) > 1)
        v = Arithmetic(solve(a,b));
      else
        v = Arithmetic(mldivide(a,b));
      end
    end
    
        
    rank(self)
    sum_square(self)
    linspace(self)
    cross(self)
    skew(self)
    inv_skew(self)
    det(self)
    inv(self)
    trace(self)
    dot(self)
    polyval(self)
    diag(self)
    solve(self)
    jacobian(self)
    jtimes(self)
    
    plus(self)
    minus(self)
    times(self)
    abs(self)
    sqrt(self)
    sin(self)
    cos(self)
    tan(self)
    atan(self)
    asin(self)
    acos(self)
    tanh(self)
    sinh(self)
    cosh(self)
    atanh(self)
    asinh(self)
    acosh(self)
    exp(self)
    log(self)
    log10(self)
    floor(self)
    power(self)
    mod(self)
    atan2(self)
    min(self)
    max(self)
    
  end
  
  methods
    
    function v = value(self)
      v = self.thisValue;
    end
    
    function setValue(self,v)
      self.thisValue = v;
    end
    
     
    
    
  end
  
end

