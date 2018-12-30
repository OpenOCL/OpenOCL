classdef Variable < handle
    % VARIABLE Default implementation of arithemtic operations for
    % variables
    % This class can be derived from to implement new arithemtics for 
    % variables e.g. casadi variables, or symbolic variables.
  
  properties
    type
    positions
    val
    
  end
  
  methods (Static)
    
    function obj = createLike(input,type,pos,val)
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
      narginchk(4,4);
      
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(type,pos,input.mx,val);
      elseif isa(input,'SymVariable')
        obj = SymVariable(type,pos,val);
      elseif isa(input,'Variable')
        obj = Variable(type,type,pos,val);
      else
        error('Variable type not implemented.');
      end
    end
    
    function obj = createFromVariable(type,pos,var)
      if isa(variable,'CasadiVariable')
        obj = CasadiVariable(type,var.positions,var.mx,var.val);
      elseif isa(variable,'SymVariable')
        obj = SymVariable(type,pos,var.val);
      elseif isa(variable,'Variable')
        obj = Variable(type,pos,var.val);
      else
        error('Variable not implemented.');
      end
    end
    
    function obj = createMatrixLike(input, value)
      % obj = createMatrixLike(input,val)
      % Factory method to create Matrix valued variables with the type of
      % input.
      s = size(value);
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(OclMatrix(s),1:prod(s),input.mx,Value(value));
      elseif isa(input,'SymVariable')
        obj = SymVariable(OclMatrix(s),1:prod(s),Value(value));
      elseif isa(input,'Variable')
        obj = Variable(OclMatrix(s),1:prod(s),Value(value));
      else
        error('Variable type not implemented.');
      end
    end
    
    function obj = Matrix(val)
      obj = Variable(OclMatrix(size(val)),1:prod(size(val)),Value(val));
    end
    
  end % methods(static)
  
  methods
    
    function self = Variable(type,positions,val)
      narginchk(3,3);
      assert(isa(type,'OclStructure'));
      assert(isa(val,'Value'));
      
      self.type = type;
      self.positions = positions;
     
      self.val = val;
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
      % v = 1
      % v(1) = 1
      % v.get(1) = 1
      % v.value(1) = 1
      
      if isa(v,'Variable') 
        v = v.val;
      end
      
      if numel(s)==1 && strcmp(s.type,'()')
        self.get(s.subs{:}).set(v);
      else
        v = subsasgn(self.get(s.subs),s(2:end),v);
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
          [t,p] = self.type.get(self.positoins,in1);
          r = Variable.createLike(self,t,p,self.val);
        else
          % get(id,selector)
          [t,p] = self.type.get(self.positions,in1);
          [t,p] = t.get(p,in2);
          r = Variable.createLike(self,t,p,self.val);
        end
      else
        if nargin == 2
          % get(index)
          if isAllOperator(in1)
            r = self;
          else
            [t,p] = self.type.get(self.positions,in1);
            r = Variable.createLike(self,t,p,self.val);
          end
        else
          % get(row,col)
          if isAllOperator(in1) && isAllOperator(in2)
            r = self;
          else
            [t,p] = self.type.get(self.positions,in1,in2);
            r = Variable.createLike(self,t,p,self.val);
          end
        end
      end
    end
    %%%
    function set(self,val,varargin)
      % set(val)
      % set(scalar)
      % set(matrix)
      % set(tensor)
      % set(val,slice1,slice2,slice3)
      [pos,N,M,K] = self.type.getPositions(self.positions);
      
      if isnumeric(pos)
        pos = {pos};
      end
      
      pout = cell(1,K);
      for k=1:K
        p = reshape(pos{k},[N,M]);
        if nargin==3
         p = p(slice1);
        elseif nargin==4
          p = p(slice1,slice2);  
        end
        pout{k} = p;
      end
      if nargin==5
        pout = pout(slice3);
      end
      pout = cell2mat(pout);
      self.val.set(val,pout);
    end % set
    
    function vout = value(self,slice1,slice2,slice3)
      % value()
      % value(slice1,slice2,slice3)
      value = self.val.get();
      [pos,N,M,K] = self.type.getPositions(self.positions);
      
      if isnumeric(pos)
        pos = {pos};
      end
      
      
      vout = cell(1,K);
      for k=1:K
        v = reshape(value(pos{k}),[N,M]);
        if nargin==2
          v = v(slice1);
        elseif nargin==3
          v = v(slice1,slice2);  
        end
        vout{k} = v;
      end
      if nargin==4
        vout = vout(slice3);
      end
      if length(vout)==1
        vout = vout{1};
      end
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
        vv = varargin{k};
        if isa(vv,'Variable')
          inValues{k} = vv.value;
          obj = vv;
        else
          inValues{k} = vv;
        end
      end    
      v = Variable.createMatrixLike(obj,horzcat(inValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        vv = varargin{k};
        if isa(vv,'Variable')
          inValues{k} = vv.value;
          obj = vv;
        else
          inValues{k} = vv;
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
    
    function n = ppp(self)
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

