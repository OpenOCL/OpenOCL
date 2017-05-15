classdef Arithmetic < handle
  
  methods (Abstract)
    value(self)
  end
  
  methods
    
    %%% matrix and vector wise operations
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
      v = Expression(horzcat(inValues{:}));
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
      v = Expression(vertcat(inValues{:}));
    end
    
%     function varargout = subsref(self,s)
%       if numel(s) == 1 && strcmp(s.type,'()')
%         [varargout{1}] = Arithmetic(self.value.subsref(s));
%       elseif numel(s) > 1 && strcmp(s(1).type,'()')
%         v = Arithmetic(self.value.subsref(s(1)));
%         [varargout{1:nargout}] = subsref(v,s(2:end));
%       else
%         [varargout{1:nargout}] = builtin('subsref',self,s);
%       end
%     end
    
%     function self = subsasgn(self,s,v)
%       if numel(s)==1 && strcmp(s.type,'()')
%         v = subsasgn(self.value,s,v);
%         self.setValue(v);
%       else
%         self.setValue(builtin('subsasgn',self.value,s,v));
%       end
%     end
    
    function v = mtimes(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(mtimes(a,b));
    end
   
    function v = ctranspose(self)
      % There is no complex transpose with casadi, so we call matrix
      % transpose.
      v = transpose(self);
    end
    function v = transpose(self)
      v = Expression(transpose(self.value));
    end
    
    function v = reshape(self,varargin)
      v = Expression(reshape(self.value,varargin{:}));
    end
    
    function v = triu(self)
      v = Expression(triu(self.value));
    end
    
    function v = repmat(self,varargin)
      v = Expression(repmat(self.value,varargin{:}));
    end
    
    function v = sum(a)
      v = Expression(sum(a.value));
    end
    
    function v = norm(a,varargin)
      v = Expression(norm(a.value,varargin{:}));
    end
    
    function v = mpower(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(mpower(a,b));
    end
    
    function v = mldivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      if (numel(a) > 1) && (numel(b) > 1)
        v = Expression(solve(a,b));
      else
        v = Expression(mldivide(a,b));
      end
    end
    
    function v = mrdivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(mrdivide(a,b));
    end
    
    function v = cross(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(cross(a,b));
    end
    
    function v = dot(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(dot(a,b));
    end
    
    function v = inv(self)
      v = Expression(inv(self.value));
    end
    
    function v = det(self)
      v = Expression(det(self.value));
    end
    
    function v = trace(self)
      v = Expression(trace(self.value));
    end
    
    function v = diag(self)
      v = Expression(diag(self.value));
    end
    
    function v = polyval(p,a)
      if isa(p,'Arithmetic') 
        p = p.value;
      end  
      if isa(a,'Arithmetic')
        a = a.value;
      end   
      v = Expression(polyval(p,a));
    end
    
    function v = jacobian(ex,arg)
      if isa(ex,'Arithmetic') 
        ex = ex.value;
      end  
      if isa(arg,'Arithmetic')
        arg = arg.value;
      end  
      v = Expression(jacobian(ex,arg));
    end
    
    function r = jtimes(ex,arg,v)
      if isa(ex,'Arithmetic') 
        ex = ex.value;
      end  
      if isa(arg,'Arithmetic')
        arg = arg.value;
      end
      if isa(v,'Arithmetic')
        v = v.value;
      end  
      r = Expression(jtimes(ex,arg,v));
    end
    
    %%% element wise operations
    function v = plus(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(plus(a,b));
    end
    
    function v = minus(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(minus(a,b));
    end
    
    function v = times(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(times(a,b));
    end
    
    function v = power(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(power(a,b));
    end
    
    function v = rdivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(rdivide(a,b));
    end
    
    function v = ldivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(ldivide(a,b));
    end
    
    function v = atan2(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Expression(atan2(a,b));
    end
    
    function v = abs(self)
      v = Expression(abs(self.value));
    end

    function v = sqrt(self)
      v = Expression(sqrt(self.value));
    end
    
    function v = sin(self)
      v = Expression(sin(self.value));
    end
    
    function v = cos(self)
      v = Expression(cos(self.value));
    end
    
    function v = tan(self)
      v = Expression(tan(self.value));
    end
    
    function v = atan(self)
      v = Expression(atan(self.value));
    end
    
    function v = asin(self)
      v = Expression(asin(self.value));
    end
    
    function v = acos(self)
      v = Expression(acos(self.value));
    end
    
    function v = tanh(self)
      v = Expression(tanh(self.value));
    end
    
    function v = cosh(self)
      v = Expression(cosh(self.value));
    end
    
    function v = sinh(self)
      v = Expression(sinh(self.value));
    end
    
    function v = atanh(self)
      v = Expression(atanh(self.value));
    end
    
    function v = asinh(self)
      v = Expression(asinh(self.value));
    end
    
    function v = acosh(self)
      v = Expression(acosh(self.value));
    end
    
    function v = exp(self)
      v = Expression(exp(self.value));
    end
    
    function v = log(self)
      v = Expression(log(self.value));
    end
    
  end
  
end

