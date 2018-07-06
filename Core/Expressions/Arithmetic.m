classdef Arithmetic < handle
    % ARITHMETIC Default implementation for arithemtic operations
    %    Methods can be overridden to provide operations for specific data
    %    types, e.g. casadi variables, or symbolic variables.
  
  properties
    varStructure
    thisValue
  end
  
  methods (Static)
    
    function obj = create(arithmeticObj,structureType,varargin)
      % obj = create(arithmeticObj,structureType)
      % obj = create(arithmeticObj,structureType,value)
      % Factory method to create Arithmetic objects
      
      if isa(arithmeticObj,'CasadiArithmetic')
        obj = CasadiArithmetic(structureType,varargin{:});
      elseif isa(arithmeticObj,'SymArithmetic')
        obj = SymArithmetic(structureType,varargin{:});
      elseif isa(arithmeticObj,'Arithmetic')
        obj = Arithmetic(structureType,varargin{:});
      else
        error('Arithmetic not implemented.');
      end
      
    end
    
    function obj = createFromArithmetic(structure, arithmetic)
      if isa(arithmetic,'CasadiArithmetic')
        obj = CasadiArithmetic(structure,arithmetic.value);
      elseif isa(arithmetic,'SymArithmetic')
        obj = SymArithmetic(structure,arithmetic.value);
      elseif isa(arithmetic,'Arithmetic')
        obj = Arithmetic(structure,arithmetic.value);
      else
        error('Arithmetic not implemented.');
      end
    end
    
    
    function obj = createExpression(arithmeticObj,value)
      % obj = createExpression(arithmeticObj,value)
      % Factory method to create Matrix valued Arithmetic objects
      
      if isa(arithmeticObj,'CasadiArithmetic')
        obj = CasadiArithmetic(MatrixStructure(size(value)),value);
      elseif isa(arithmeticObj,'SymArithmetic')
        obj = SymArithmetic(MatrixStructure(size(value)),value);
      elseif isa(arithmeticObj,'Arithmetic')
        obj = Arithmetic(MatrixStructure(size(value)),value);
      else
        error('Arithmetic not implemented.');
      end
      
    end
    
    function obj = Matrix(value)
      obj = Arithmetic(MatrixStructure(size(value)),value);
    end
    
  end
  
  methods
    
    function self = Arithmetic(varStructure,value)
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
        r = Arithmetic.create(self,self.varStructure.get(in1),self.thisValue);
      else
        r = Arithmetic.create(self,self.varStructure.get(in1,in2),self.thisValue);
      end
    end
    %%%
    
    
    function set(self,valueIn)
      
      if isa(valueIn,'Arithmetic')
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
        if isa(val,'Arithmetic')
          inValues{k} = val.value;
          obj = val;
        else
          inValues{k} = val;
        end
      end    
      v = Arithmetic.createExpression(obj,horzcat(inValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      inValues = cell(1,N);
      for k=1:numel(varargin)
        val = varargin{k};
        if isa(val,'Arithmetic')
          inValues{k} = val.value;
          obj = val;
        else
          inValues{k} = val;
        end
      end
      v = Arithmetic.createExpression(obj,vertcat(inValues{:}));
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
      
      if isa(v,'Arithmetic') 
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
      slicedVar = Arithmetic.createExpression(self,val(varargin{:}));
    end

    % TODO: test
    function n = numArgumentsFromSubscript(self,s,indexingContext)
      switch indexingContext
        case matlab.mixin.util.IndexingContext.Statement
          n=1;
        case matlab.mixin.util.IndexingContext.Expression
          n=1;
      end
    end
    
    
    
    function v = uplus(a)
      v = Arithmetic.createExpression(a,uplus(a.value));
    end
    
    function v = uminus(a)
      v = Arithmetic.createExpression(a,uminus(a.value));
    end
    
    function v = mtimes(a,b)
      if isa(a,'Arithmetic') 
        obj = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        obj = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(obj,mtimes(a,b));
    end
   
    function v = ctranspose(self)
      % There is no complex transpose with casadi, so we call matrix
      % transpose.
      v = transpose(self);
    end
    function v = transpose(self)
      v = Arithmetic.createExpression(self,transpose(self.value));
    end
    
    function v = reshape(self,varargin)
      v = Arithmetic.createExpression(self,reshape(self.value,varargin{:}));
    end
    
    function v = triu(self)
      v = Arithmetic.createExpression(self,triu(self.value));
    end
    
    function v = repmat(self,varargin)
      v = Arithmetic.createExpression(self,repmat(self.value,varargin{:}));
    end
    
    function v = sum(self)
      v = Arithmetic.createExpression(self,sum(self.value));
    end
    
    function v = norm(self,varargin)
      v = Arithmetic.createExpression(self,norm(self.value,varargin{:}));
    end
    
    function v = mpower(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,mpower(a,b));
    end
    
    function v = mldivide(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      if (numel(a) > 1) && (numel(b) > 1)
        v = Arithmetic.createExpression(self,solve(a,b));
      else
        v = Arithmetic.createExpression(self,mldivide(a,b));
      end
    end
    
    function v = mrdivide(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,mrdivide(a,b));
    end
    
    function v = cross(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,cross(a,b));
    end
    
    function v = dot(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,dot(a,b));
    end
    
    function v = inv(self)
      v = Arithmetic.createExpression(self,inv(self.value));
    end
    
    function v = det(self)
      v = Arithmetic.createExpression(self,det(self.value));
    end
    
    function v = trace(self)
      v = Arithmetic.createExpression(self,trace(self.value));
    end
    
    function v = diag(self)
      v = Arithmetic.createExpression(self,diag(self.value));
    end
    
    function v = polyval(p,a)
      if isa(p,'Arithmetic') 
        self = p;
        p = p.value;
      end  
      if isa(a,'Arithmetic')
        self = a;
        a = a.value;
      end   
      v = Arithmetic.createExpression(self,polyval(p,a));
    end
    
    function v = jacobian(ex,arg)
      if isa(ex,'Arithmetic') 
        self = ex;
        ex = ex.value;
      end  
      if isa(arg,'Arithmetic')
        self = arg;
        arg = arg.value;
      end  
      v = Arithmetic.createExpression(self,jacobian(ex,arg));
    end
    
    function r = jtimes(ex,arg,v)
      if isa(ex,'Arithmetic') 
        self = ex;
        ex = ex.value;
      end  
      if isa(arg,'Arithmetic')
        self = arg;
        arg = arg.value;
      end
      if isa(v,'Arithmetic')
        self = v;
        v = v.value;
      end  
      r = Arithmetic.createExpression(self,jtimes(ex,arg,v));
    end
    
    %%% element wise operations
    function v = plus(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,plus(a,b));
    end
    
    function v = minus(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,minus(a,b));
    end
    
    function v = times(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,times(a,b));
    end
    
    function v = power(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,power(a,b));
    end
    
    function v = rdivide(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,rdivide(a,b));
    end
    
    function v = ldivide(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,ldivide(a,b));
    end
    
    function v = atan2(a,b)
      if isa(a,'Arithmetic') 
        self = a;
        a = a.value;
      end
      if isa(b,'Arithmetic')
        self = b;
        b = b.value;
      end
      v = Arithmetic.createExpression(self,atan2(a,b));
    end
    
    function v = abs(self)
      v = Arithmetic.createExpression(self,abs(self.value));
    end

    function v = sqrt(self)
      v = Arithmetic.createExpression(self,sqrt(self.value));
    end
    
    function v = sin(self)
      v = Arithmetic.createExpression(self,sin(self.value));
    end
    
    function v = cos(self)
      v = Arithmetic.createExpression(self,cos(self.value));
    end
    
    function v = tan(self)
      v = Arithmetic.createExpression(self,tan(self.value));
    end
    
    function v = atan(self)
      v = Arithmetic.createExpression(self,atan(self.value));
    end
    
    function v = asin(self)
      v = Arithmetic.createExpression(self,asin(self.value));
    end
    
    function v = acos(self)
      v = Arithmetic.createExpression(self,acos(self.value));
    end
    
    function v = tanh(self)
      v = Arithmetic.createExpression(self,tanh(self.value));
    end
    
    function v = cosh(self)
      v = Arithmetic.createExpression(self,cosh(self.value));
    end
    
    function v = sinh(self)
      v = Arithmetic.createExpression(self,sinh(self.value));
    end
    
    function v = atanh(self)
      v = Arithmetic.createExpression(self,atanh(self.value));
    end
    
    function v = asinh(self)
      v = Arithmetic.createExpression(self,asinh(self.value));
    end
    
    function v = acosh(self)
      v = Arithmetic.createExpression(self,acosh(self.value));
    end
    
    function v = exp(self)
      v = Arithmetic.createExpression(self,exp(self.value));
    end
    
    function v = log(self)
      v = Arithmetic.createExpression(self,log(self.value));
    end
    
  end
  
end

