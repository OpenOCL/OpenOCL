classdef Arithmetic < handle
  
  properties
    pseudoValue
  end
  
  methods
    
    function self = Arithmetic(v)
      if nargin == 1
        self.setValue(v);
      end
    end
    
    %%% matrix and vector wise operations
%     function v = horzcat(varargin)
%       N = numel(varargin);
%       inValues = cell(1,N);
%       for k=1:numel(varargin)
%         val = varargin{k};
%         if isa(val,'Arithmetic')
%           inValues{k} = val.value;
%         else
%           inValues{k} = val;
%         end
%       end    
%       v = Arithmetic(horzcat(inValues{:}));
%     end
%     
%     function v = vertcat(varargin)
%       N = numel(varargin);
%       inValues = cell(1,N);
%       for k=1:numel(varargin)
%         val = varargin{k};
%         if isa(val,'Arithmetic')
%           inValues{k} = val.value;
%         else
%           inValues{k} = val;
%         end
%       end
%       v = Arithmetic(vertcat(inValues{:}));
%     end
%     
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
%     
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
    
    function v = cross(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(cross(a,b));
    end
    
    function v = dot(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(dot(a,b));
    end
    
    function v = inv(self)
      v = Arithmetic(inv(self.value));
    end
    
    function v = det(self)
      v = Arithmetic(det(self.value));
    end
    
    function v = trace(self)
      v = Arithmetic(trace(self.value));
    end
    
    function v = diag(self)
      v = Arithmetic(diag(self.value));
    end
    
    function v = polyval(p,a)
      if isa(p,'Arithmetic') 
        p = p.value;
      end  
      if isa(a,'Arithmetic')
        a = a.value;
      end   
      v = Arithmetic(polyval(p,a));
    end
    
    function v = jacobian(ex,arg)
      if isa(ex,'Arithmetic') 
        ex = ex.value;
      end  
      if isa(arg,'Arithmetic')
        arg = arg.value;
      end  
      v = Arithmetic(jacobian(ex,arg));
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
      r = Arithmetic(jtimes(ex,arg,v));
    end
    
    %%% element wise operations
    function v = plus(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(plus(a,b));
    end
    
    function v = minus(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(minus(a,b));
    end
    
    function v = times(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(times(a,b));
    end
    
    function v = power(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(power(a,b));
    end
    
    function v = rdivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(rdivide(a,b));
    end
    
    function v = ldivide(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(ldivide(a,b));
    end
    
    function v = atan2(a,b)
      if isa(a,'Arithmetic') 
        a = a.value;
      end
      if isa(b,'Arithmetic')
        b = b.value;
      end
      v = Arithmetic(atan2(a,b));
    end
    
    function v = abs(self)
      v = Arithmetic(abs(self.value));
    end

    function v = sqrt(self)
      v = Arithmetic(sqrt(self.value));
    end
    
    function v = sin(self)
      v = Arithmetic(sin(self.value));
    end
    
    function v = cos(self)
      v = Arithmetic(cos(self.value));
    end
    
    function v = tan(self)
      v = Arithmetic(tan(self.value));
    end
    
    function v = atan(self)
      v = Arithmetic(atan(self.value));
    end
    
    function v = asin(self)
      v = Arithmetic(asin(self.value));
    end
    
    function v = acos(self)
      v = Arithmetic(acos(self.value));
    end
    
    function v = tanh(self)
      v = Arithmetic(tanh(self.value));
    end
    
    function v = cosh(self)
      v = Arithmetic(cosh(self.value));
    end
    
    function v = sinh(self)
      v = Arithmetic(sinh(self.value));
    end
    
    function v = atanh(self)
      v = Arithmetic(atanh(self.value));
    end
    
    function v = asinh(self)
      v = Arithmetic(asinh(self.value));
    end
    
    function v = acosh(self)
      v = Arithmetic(acosh(self.value));
    end
    
    function v = exp(self)
      v = Arithmetic(exp(self.value));
    end
    
    function v = log(self)
      v = Arithmetic(log(self.value));
    end
    

    
  end
  
  methods
    
    function v = value(self)
      v = self.pseudoValue;
    end
    
    function setValue(self,v)
      self.pseudoValue = v;
    end
    
  end
  
end

