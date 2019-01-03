classdef Variable < handle
    % VARIABLE Default implementation of arithemtic operations for
    % variables
    % This class can be derived from to implement new arithemtics for 
    % variables e.g. casadi variables, or symbolic variables.
  
  properties
    val
    positions
    type
  end
  
  methods (Static)
    
    %%% factory methods
    function var = createFromValue(type,value)
      if isnumeric(value)
        var = Variable.createNumeric(type,value);
      elseif isa(value,'casadi.MX')
        var = CasadiVariable.create(type,true,value);
      elseif isa(value,'casadi.SX')
        var = CasadiVariable.create(type,false,value);
      else
        oclError('Not implemented for this type of variable.')
      end
    end
    
    function var = createMatrix(value)
      type = OclMatrix(size(value));
      obj = createFromValue(type,value);
    end

    function obj = createMatrixLike(~,value)
      % obj = createMatrixLike(input,value)
      type = OclMatrix(size(value));
      obj = createFromValue(type,value);
    end
    
    function var = createNumeric(type,value)
        [N,M,K] = type.size();
        v = OclValue(zeros(1,N,M,K));
        p = reshape(1:N*M*K,N,M,K);
        var = Variable(type,p,v);
        var.set(value);
    end
    
    function var = Matrix(value)
      % create numeric matrix
      assert(isnumeric(value));
      Variable.create(OclMatrix(size(value)),value)
      var = Variable.create(OclMatrix(size(value)),value);
    end
    %%% end factory methods
    
    function val = getValue(val)
      if isa(val,'Variable')
        val = val.value;
      end
    end
    
    function val = getValueAsColumn(val)
      val = Variable.getValue();
      val = val(:);
    end
    
  end % methods(static)
  methods
    function self = Variable(type,positions,val)
      narginchk(3,3);
      assert(isa(type,'OclStructure'));
      assert(isnumeric(positions));
      assert(isa(val,'Value'));
      self.type = type;
      self.positions = positions;
      self.val = val;
    end
    
    function s = str(self,value)
      
      if nargin==1
        value = self.value;
        if isnumeric(value);
          value = mat2str(value);
        end
      end
      
      childrenString = '';
      if isa(self.type, 'OclTree')
        childrenString = 'Children: ';
        names = fieldnames(self.type.childrens);
        for i=length(names)
          childrenString = [childrenString, names{i}. ' '];
        end
        childrenString = [childrenString, '\n'];
      end
      
      r = sprintf([ ...
                   'Size: ', self.size(), '\n' ....
                   'Type: ', class(self.type), '\n' ...
                   childrenString, ...
                   'Value: ', value, '\n' ...
                   ]);
    end
    
    function disp(self)
      disp(self.str());
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
      elseif numel(s) > 0 && strcmp(s(1).type,'.')
        % v.something or v.something()
        id = s(1).subs;
        if isa(self.type,'OclTree') && isfield(self.type.children,id) && numel(s) == 1
          % v.x
          [varargout{1}] = self.get(s.subs);
        elseif isa(self.type,'OclTree') && isfield(self.type.children,id)
          % v.x.get(3).set(2).value || v.x.y.get(1)
          v = self.get(s(1).subs);
          [varargout{1:nargout}] = subsref(v,s(2:end));
        else
          % v.value || v.set(1) || v.get(4).set(3).x.value
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
      % v* = Variable
      
      v = Variable.getValue(v);
      
      if numel(s)==1 && strcmp(s.type,'()')
        self.get(s.subs{:}).set(v);
      else
        v = subsasgn(self.get(s.subs),s(2:end),v);
        self.set(builtin('subsasgn',self,s,v));
      end
    end
    
    %%% delegate methods to OclValue
    function set(self,val,varargin)
      % set(value)
      % set(value,slice1,slice2,slice3)
      self.val.set(self.type,self.positions,val,varargin{:})
    end
    function v = value(self)
      v = self.val.value(self.type,self.positions);
    end
    %%%    
    
    function s = size(self)
      s = size(self.positions);      
    end

    function r = get(self,varargin)
      % r = get(self,id)
      % r = get(self,id,index)
      % r = get(self,index)
      % r = get(self,dim1,dim2,dim3)
      function t = isAllOperator(in)
        t = strcmp(in,'all') || strcmp(in,':');
      end
      in1 = varargin{1};
      if ischar(in1) && ~isAllOperator(in1) && ~strcmp(in1,'end')
        if nargin == 2
          % get(id)
          [t,p] = self.type.get(self.positions,in1);
          v = Variable(t,p,self.val);
          r = v.convertTo(self);
        else
          % get(id,selector)
          [t,p] = self.type.get(self.positions,in1,varargin{2});
          v = Variable(t,p,self.val);
          r = v.convertTo(self);
        end
      else
        % slice
        for k=1:length(varargin)
          if isAllOperator(varargin{k})
            varargin{k} = (1:size(self.positions,k)).';
          elseif strcmp(varargin{k},'end')
            varargin{k} = size(self.positions,k);
          end
        end
        [t,p] = self.type.get(self.positions,varargin{:});
        v = Variable(t,p,self.val);
        r = v.convertTo(self);
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
    
    function n = properties(self)
      % DO NOT CHANGE THIS FUNCTION!
      % It is automatically renamed for Octave as properties is not 
      % allowed as a function name.
      %
      % Tab completion in Matlab for custom variables
      n = [fieldnames(self);fieldnames(self.type.children)];	
    end
  end
end

