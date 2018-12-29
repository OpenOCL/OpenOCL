classdef Variable < handle
    % VARIABLE Default implementation of arithemtic operations for
    % variables
    % This class can be derived from to implement new arithemtics for 
    % variables e.g. casadi variables, or symbolic variables.
  
  properties
    type
    val
  end
  
  methods (Static)
    
    function obj = createLike(input,type,varargin)
      % obj = createLike(input,type)
      % obj = createLike(input,type,val)
      %
      % Factory method to create Variables with the same type as
      % given input.
      %
      % Args:
      %   input (Variable): Inherit variable type of this object.
      %   type (type): type of the variable.
      %   val: Value to asign to the variable (optional).
      
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(type,input.mx,varargin{:});
      elseif isa(input,'SymVariable')
        obj = SymVariable(type,varargin{:});
      elseif isa(input,'Variable')
        obj = Variable(type,varargin{:});
      else
        error('Variable type not implemented.');
      end
    end
    
    function obj = createFromVariable(type, variable)
      if isa(variable,'CasadiVariable')
        obj = CasadiVariable(type,variable.mx,variable.value);
      elseif isa(variable,'SymVariable')
        obj = SymVariable(type,variable.value);
      elseif isa(variable,'Variable')
        obj = Variable(type,variable.value);
      else
        error('Variable not implemented.');
      end
    end
    
    function obj = createMatrixLike(input, val)
      % obj = createMatrixLike(input,val)
      % Factory method to create Matrix valued variables with the type of
      % input.
      
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(OclMatrix(size(val)),input.mx,val);
      elseif isa(input,'SymVariable')
        obj = SymVariable(OclMatrix(size(val)),val);
      elseif isa(input,'Variable')
        obj = Variable(OclMatrix(size(val)),val);
      else
        error('Variable type not implemented.');
      end
    end
    
    function obj = Matrix(val)
      obj = Variable(OclMatrix(size(val)),val);
    end
    
  end % methods(static)
  
  methods
    
    function self = Variable(type,val)
      
      if isa(type,'Variable')
        type = type.type;
      end
      
      self.type = type;
      
      if nargin == 1
        self.val = Value(zeros(prod(type.size),1));
      end
      
      if nargin ==2 
        if isa(val,'Value')
          self.val = val;
        else
          self.val = Value(zeros(prod(type.size),1));
          self.set(val);
        end
      end
    end
    
    function varargout = subsref(self,s)
      % v(1)
      % v.x
      % v.value
      % v.set(4)
      % v.dot(w)
      % ...
      
      if numel(s) == 1 && strcmp(s.type,'()')
        % v(1)
        [varargout{1}] = self.get(s.subs{:});
      elseif numel(s) > 1 && strcmp(s(1).type,'()')
        % v(1).something().a
        v = self.get(s(1).subs{:});
        [varargout{1:nargout}] = subsref(v,s(2:end));
      elseif ~numel(s) == 0 && strcmp(s(1).type,'.')
        % v.something or v.something()
        id = s(1).subs;
        if isa(self.type,'OclTree') && isfield(self.type.children,id)
          % v.x or v.x(1)
          if numel(s) > 1
            selector = s(2).subs{1};
            v = self.get(id).get(selector);
            [varargout{1:nargout}] = subsref(v,s(3:end));
          else
            % v.x
            v = self.get(id);
            [varargout{1:nargout}] = v;
          end
        else
          % x.aFunction()
          [varargout{1:nargout}] = builtin('subsref',self,s);
        end
      else
        oclError('Not supported.');
      end
    end % subsref
    
    function self = subsasgn(self,s,v)
      
      if isa(v,'Variable') 
        v = v.value;
      end
      
      if numel(s)==1 && strcmp(s.type,'()')
        v = subsasgn(self.val,s,v);
        self.set(v);
      else
        self.set(builtin('subsasgn',self,s,v));
      end
    end
    
    %%% Delegate methods of Ocltype
    function l = length(self)
      l = max(size(self));
    end
    function s = size(self,varargin)
      s = self.type.size(varargin{:});
    end
    function r = positions(self)
      r = self.type.positions;
    end
    function r = get(self,in1,in2)
      % r = get(self,id)
      % r = get(self,id,index)
      % r = get(self,index)
      % r = get(self,row,col)
      
      function t = isAllOperator(in)
        t = strcmp(in,'all') || strcmp(in,':');
        if t
          in = ':';
        end
      end
      
      if ischar(in1) && ~(isAllOperator(in1) || strcmp(in1,'end'))
        if nargin == 2
          % get(id)
          r = Variable.createLike(self,self.type.get(in1),self.value);
        else
          % get(id,selector)
          r = Variable.createLike(self,self.type.get(in1,in2),self.value);
        end
      else
        if nargin == 2
          % get(index)
          if isAllOperator(in1)
            r = self;
          else
            r = Variable.createLike(self,self.type.get(in1),self.value);
          end
        else
          % get(row,col)
          if isAllOperator(in1) && isAllOperator(in2)
            r = self;
          else
            r = Variable.createLike(self,self.type.get(in1,in2),self.value);
          end
        end
      end
    end
    %%%
    function set(self,valueIn,varargin)
      % set(val)
      % set(val,slice1,slice2,slice3)
      [pos,N,M,K] = self.type.getPositions();
      val = valueIn(pos);
      if nargin > 2
        val = reshape(val,N,M,K);
        val = val(varargin{:})
        val = reshape(val,l*l*m,1);
      end
      self.val.set(val)
    end % set
    
    function v = value(self,varargin)
      % value()
      % value(slice1,slice2,slice3)
      v = self.val.get();
      [pos,N,M,K] = self.type.getPositions();
      
      v = reshape(v(pos),N,M,K);
      v = v(varargin{:});
    end
    
    function y = linspace(d1,d2,n)
      n1 = n-1;
      y = d1 + (0:n1).*(d2 - d1)/n1;
    end
    
    %%% matrix and vector wise operations
    function v = horzcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        val = varargin{k};
        if isa(val,'Variable')
          inValues{k} = val.value;
          obj = val;
        else
          inValues{k} = val;
        end
      end    
      v = Variable.createMatrixLike(obj,horzcat(inValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        val = varargin{k};
        if isa(val,'Variable')
          inValues{k} = val.value;
          obj = val;
        else
          inValues{k} = val;
        end
      end
      v = Variable.createMatrixLike(obj,vertcat(inValues{:}));
    end
    
    function v = uplus(a)
      v = Variable.createMatrixLike(a,uplus(a.value));
    end
    
    function v = uminus(a)
      v = Variable.createMatrixLike(a,uminus(a.value));
    end
    
    function v = mtimes(a,b)
      if isa(a,'Variable') 
        obj = a;
        a = a.value;
      end
      if isa(b,'Variable')
        obj = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(obj,mtimes(a,b));
    end
   
    function v = ctranspose(self)
      % There is no complex transpose with casadi, so we call matrix
      % transpose.
      v = transpose(self);
    end
    function v = transpose(self)
      v = Variable.createMatrixLike(self,transpose(self.value));
    end
    
    function v = reshape(self,varargin)
      v = Variable.createMatrixLike(self,reshape(self.value,varargin{:}));
    end
    
    function v = triu(self)
      v = Variable.createMatrixLike(self,triu(self.value));
    end
    
    function v = repmat(self,varargin)
      v = Variable.createMatrixLike(self,repmat(self.value,varargin{:}));
    end
    
    function v = sum(self)
      v = Variable.createMatrixLike(self,sum(self.value));
    end
    
    function v = norm(self,varargin)
      v = Variable.createMatrixLike(self,norm(self.value,varargin{:}));
    end
    
    function v = mpower(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,mpower(a,b));
    end
    
    function v = mldivide(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      if (numel(a) > 1) && (numel(b) > 1)
        v = Variable.createMatrixLike(self,solve(a,b));
      else
        v = Variable.createMatrixLike(self,mldivide(a,b));
      end
    end
    
    function v = mrdivide(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,mrdivide(a,b));
    end
    
    function v = cross(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,cross(a,b));
    end
    
    function v = dot(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,dot(a,b));
    end
    
    function v = inv(self)
      v = Variable.createMatrixLike(self,inv(self.value));
    end
    
    function v = det(self)
      v = Variable.createMatrixLike(self,det(self.value));
    end
    
    function v = trace(self)
      v = Variable.createMatrixLike(self,trace(self.value));
    end
    
    function v = diag(self)
      v = Variable.createMatrixLike(self,diag(self.value));
    end
    
    function v = polyval(p,a)
      if isa(p,'Variable') 
        self = p;
        p = p.value;
      end  
      if isa(a,'Variable')
        self = a;
        a = a.value;
      end   
      v = Variable.createMatrixLike(self,polyval(p,a));
    end
    
    function v = jacobian(ex,arg)
      if isa(ex,'Variable') 
        self = ex;
        ex = ex.value;
      end  
      if isa(arg,'Variable')
        self = arg;
        arg = arg.value;
      end  
      v = Variable.createMatrixLike(self,jacobian(ex,arg));
    end
    
    function r = jtimes(ex,arg,v)
      if isa(ex,'Variable') 
        self = ex;
        ex = ex.value;
      end  
      if isa(arg,'Variable')
        self = arg;
        arg = arg.value;
      end
      if isa(v,'Variable')
        self = v;
        v = v.value;
      end  
      r = Variable.createMatrixLike(self,jtimes(ex,arg,v));
    end
    
    %%% element wise operations
    function v = plus(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,plus(a,b));
    end
    
    function v = minus(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,minus(a,b));
    end
    
    function v = times(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,times(a,b));
    end
    
    function v = power(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,power(a,b));
    end
    
    function v = rdivide(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,rdivide(a,b));
    end
    
    function v = ldivide(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,ldivide(a,b));
    end
    
    function v = atan2(a,b)
      if isa(a,'Variable') 
        self = a;
        a = a.value;
      end
      if isa(b,'Variable')
        self = b;
        b = b.value;
      end
      v = Variable.createMatrixLike(self,atan2(a,b));
    end
    
    function v = abs(self)
      v = Variable.createMatrixLike(self,abs(self.value));
    end

    function v = sqrt(self)
      v = Variable.createMatrixLike(self,sqrt(self.value));
    end
    
    function v = sin(self)
      v = Variable.createMatrixLike(self,sin(self.value));
    end
    
    function v = cos(self)
      v = Variable.createMatrixLike(self,cos(self.value));
    end
    
    function v = tan(self)
      v = Variable.createMatrixLike(self,tan(self.value));
    end
    
    function v = atan(self)
      v = Variable.createMatrixLike(self,atan(self.value));
    end
    
    function v = asin(self)
      v = Variable.createMatrixLike(self,asin(self.value));
    end
    
    function v = acos(self)
      v = Variable.createMatrixLike(self,acos(self.value));
    end
    
    function v = tanh(self)
      v = Variable.createMatrixLike(self,tanh(self.value));
    end
    
    function v = cosh(self)
      v = Variable.createMatrixLike(self,cosh(self.value));
    end
    
    function v = sinh(self)
      v = Variable.createMatrixLike(self,sinh(self.value));
    end
    
    function v = atanh(self)
      v = Variable.createMatrixLike(self,atanh(self.value));
    end
    
    function v = asinh(self)
      v = Variable.createMatrixLike(self,asinh(self.value));
    end
    
    function v = acosh(self)
      v = Variable.createMatrixLike(self,acosh(self.value));
    end
    
    function v = exp(self)
      v = Variable.createMatrixLike(self,exp(self.value));
    end
    
    function v = log(self)
      v = Variable.createMatrixLike(self,log(self.value));
    end
    
    function n = properties(self)
      % DO NOT CHANGE THIS FUNCTION!
      % It is automatically renamed for Octave as properties is not 
      % allowed as a function name.
      %
      % Tab completion in Matlab for custom variables
      n = [fieldnames(self);	
      fieldnames(self.type.getChildPointers)];	
    end
  end
end

