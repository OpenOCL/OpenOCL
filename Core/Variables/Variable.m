classdef Variable < handle
    % VARIABLE Default implementation of arithemtic operations for
    % variables
    % This class can be derived from to implement new arithemtics for 
    % variables e.g. casadi variables, or symbolic variables.
  
  properties
    varStructure
    thisValue
  end
  
  methods (Static)
    
    function obj = createLike(input,structure,varargin)
      % obj = createLike(input,structure)
      % obj = createLike(input,structure,value)
      %
      % Factory method to create Variables with the same type as
      % given input.
      %
      % Args:
      %   input (Variable): Inherit variable type of this object.
      %   structure (VarStructure): Structure of the variable.
      %   value: Value to asign to the variable (optional).
      
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(structure,input.mx,varargin{:});
      elseif isa(input,'SymVariable')
        obj = SymVariable(structure,varargin{:});
      elseif isa(input,'Variable')
        obj = Variable(structure,varargin{:});
      else
        error('Variable type not implemented.');
      end
      
    end
    
    function obj = createFromVariable(structure, variable)
      if isa(variable,'CasadiVariable')
        obj = CasadiVariable(structure,variable.mx,variable.value);
      elseif isa(variable,'SymVariable')
        obj = SymVariable(structure,variable.value);
      elseif isa(variable,'Variable')
        obj = Variable(structure,variable.value);
      else
        error('Variable not implemented.');
      end
    end
    
    
    function obj = createMatrixLike(input, value)
      % obj = createMatrixLike(input,value)
      % Factory method to create Matrix valued variables with the type of
      % input.
      
      if isa(input,'CasadiVariable')
        obj = CasadiVariable(MatrixStructure(size(value)),input.mx,value);
      elseif isa(input,'SymVariable')
        obj = SymVariable(MatrixStructure(size(value)),value);
      elseif isa(input,'Variable')
        obj = Variable(MatrixStructure(size(value)),value);
      else
        error('Variable type not implemented.');
      end
      
    end
    
    function obj = Matrix(value)
      obj = Variable(MatrixStructure(size(value)),value);
    end
    
  end
  
  methods
    
    function self = Variable(varStructure,value)
      self.varStructure = varStructure;
      
      if nargin == 1
        self.thisValue = Value(zeros(prod(varStructure.size),1));
      end
      
      if nargin ==2 
        if isa(value,'Value')
          self.thisValue = value;
        else
          self.thisValue = Value(zeros(prod(varStructure.size),1));
          self.set(value);
        end
      end
    end
    
    %%% Delegate methods of varStructure
    function l = length(self)
      l = max(size(self));
    end
    function s = size(self,varargin)
      s = self.varStructure.size(varargin{:});
    end
    function r = positions(self)
      r = self.varStructure.positions;
    end
    function r = get(self,in1,in2)
      % r = get(self,id)
      % r = get(self,id,selector)
      % r = get(self,selector)
      if nargin == 2
        r = Variable.createLike(self,self.varStructure.get(in1),self.thisValue);
      else
        r = Variable.createLike(self,self.varStructure.get(in1,in2),self.thisValue);
      end
    end
    %%%
    
    
    function set(self,valueIn)
      
      if isa(valueIn,'Variable')
        valueIn = valueIn.value;
      end
      
      positions = self.positions;
      
      if isscalar(valueIn)
        % assign scalar
        for k=1:length(positions)
          s = numel(positions{k});
          val = valueIn * ones(s,1);
          self.thisValue.set(val,positions{k});
        end
      elseif numel(positions{1}) == numel(valueIn)
        % assign same value repeatetly to each position
        for k=1:length(positions)
          p = positions{k};
          val = reshape(valueIn,size(p));
          self.thisValue.set(val,p);
        end
      elseif ismatrix(valueIn) && length(positions) == size(valueIn,2)
        % assign each column of value to each position
        for k=1:length(positions)
          self.thisValue.set(valueIn(:,k),positions{k});
        end
      else
        error('Error: Can not assign value to variable, dimensions do not match.');
      end
      
    end
    
    function v = value(self)
      
      positions = self.varStructure.positions;
      if length(positions) == 1
        s = self.size;
        v = reshape(self.thisValue.value(positions{1}),s);
      else
        % stack vectors
        v = [];
        for k=1:length(positions)
          v = [v,self.thisValue.value(positions{k})];
        end
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
    
    function varargout = subsref(self,s)
      
      if numel(s) == 1 && strcmp(s.type,'()')
        % slice on value
        [varargout{1}] = self.slice(s.subs{:});
      elseif numel(s) > 1 && strcmp(s(1).type,'()')
        % slice and call recursive
        v = self.slice(s(1).subs{:});
        [varargout{1:nargout}] = subsref(v,s(2:end));
      elseif ~numel(s) == 0 && strcmp(s(1).type,'.')
        
        try
          % try to call class method
          [varargout{1:nargout}] = builtin('subsref',self,s);
        catch e
          % get by id
          id = s(1).subs;
          
          % check if id is a children
          if ~isfield(self.varStructure.getChildPointers,id)
            throw(e);
          end
          
          if numel(s) > 1
            if strcmp(s(2).type,'()')
              % check for selector
              selector = s(2).subs{1};
              v = self.get(id,selector);
              [varargout{1:nargout}] = subsref(v,s(3:end));
            else
              v = self.get(id);
              [varargout{1:nargout}] = subsref(v,s(2:end));
            end
          else
            v = self.get(id);
            [varargout{1:nargout}] = v;
          end
        end
      else
        [varargout{1:nargout}] = self;
      end
      
      
    end
    
    function self = subsasgn(self,s,v)
      
      if isa(v,'Variable') 
        v = v.value;
      end
      
      if numel(s)==1 && strcmp(s.type,'()')
        v = subsasgn(self.value,s,v);
        self.set(v);
      else
        self.set(builtin('subsasgn',self,s,v));
      end
    end
    
    function slicedVar = slice(self,varargin)
      % slicedVar = slice(self,el)
      % slicedVar = slice(self,row,col)
      
      if nargin == 4 && varargin{3} == 1
        varargin(3) = [];
      end
      val = self.value;
      slicedVar = Variable.createMatrixLike(self,val(varargin{:}));
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
    
  end
  
end

