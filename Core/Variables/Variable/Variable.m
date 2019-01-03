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
    function var = create(type,value)
      if isnumeric(value)
        var = Variable.createNumeric(type,value);
      elseif isa(value,'casadi.MX') || isa(value,'casadi.SX')
        var = CasadiVariable.createFromValue(type,value);
      else
        oclError('Not implemented for this type of variable.')
      end
    end
    
    function var = createFromVar(type,pos,var)
      if isa(var, 'CasadiVariable')
        var = CasadiVariable(type,pos,var.mx,var.val);
      elseif isa(var,'SymVariable')
        var = SymVariable(type,pos,var.val);
      else
        var = Variable(type,pos,var.val);
      end
    end

    function obj = Matrix(value)
      % obj = createMatrixLike(input,value)
      type = OclMatrix(size(value));
      obj = Variable.create(type,value);
    end
    
    function var = createNumeric(type,value)
        [N,M,K] = type.size();
        v = OclValue(zeros(1,N,M,K));
        p = reshape(1:N*M*K,N,M,K);
        var = Variable(type,p,v);
        var.set(value);
    end
    
    function v = createFromHandleOne(fh, a, varargin)
      v = Variable.Matrix( fh(Variable.getValue(a), varargin{:}) );
    end
    
    function v = createFromHandleTwo(fh, a, b, varargin)
      a = Variable.getValue(a);
      b = Variable.getValue(b);
      if isnumeric(a) && (isa(b,'casadi.SX')||isa(b,'casadi.MX'))
        a = casadi.DM(a);  
      end
      v = Variable.Matrix(fh(a,b,varargin{:}));
    end
    %%% end factory methods
    
    function varargout = unifyValues(varargin)
      for i =1:length(varargin)
        
      end
    end
    
    function value = getValue(value)
      if isa(value,'Variable')
        value = value.value;
      end
    end
    
    function value = getValueAsColumn(value)
      value = Variable.getValue(value);
      value = value(:);
    end
  end % methods(static)
  
  methods
    function self = Variable(type,positions,val)
      narginchk(3,3);
      assert(isa(type,'OclStructure'));
      assert(isnumeric(positions));
      assert(isa(val,'OclValue'));
      self.type = type;
      self.positions = positions;
      self.val = val;
    end
    
    function r = str(self,valueStr)
      if nargin==1
        value = self.value;
        if isnumeric(value);
          valueStr = mat2str(value);
        else
          valueStr = value.char();
        end
      end
      childrenString = '';
      if isa(self.type, 'OclTree')
        childrenString = '  Children: ';
        names = fieldnames(self.type.childrens);
        for i=length(names)
          childrenString = [childrenString, names{i}, ' '];
        end
        childrenString = [childrenString, '\n'];
      end
      
      r = sprintf([ ...
                   class(self), ':\n' ....
                   '  Size: ', mat2str(self.size()), '\n' ....
                   '  Type: ', class(self.type), '\n' ...
                   childrenString, ...
                   '  Value: ', valueStr, '\n' ...
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
          r = Variable.createFromVar(t,p,self);
        else
          % get(id,selector)
          [t,p] = self.type.get(self.positions,in1,varargin{2});
          r = Variable.createFromVar(t,p,self);
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
        r = Variable.createFromVar(t,p,self);
      end
    end
    
    function y = linspace(d1,d2,n)
      n1 = n-1;
      y = d1 + (0:n1).*(d2 - d1)/n1;
    end
    
    %%% operators
    % single argument
    function v = uplus(self)
      v = Variable.createFromHandleOne(@(self)self.uplus(),self);
    end
    function v = uminus(self)
      v = Variable.createFromHandleOne(@(self)self.uminus(),self);
    end
   
    function v = ctranspose(self)
      oclWarning(['Complex transpose is not defined. Using matrix transpose ', ...
                  'instead. Use the .'' operator instead on the '' operator!']);
      v = self.transpose();
    end
    function v = transpose(self)
      v = Variable.createFromHandleOne(@(self)self.transpose(),self);
    end
    
    function v = reshape(self,varargin)
      v = Variable.createFromHandleOne(@(self,varargin)self.reshape(varargin{:}),self,varargin{:});
    end
    
    function v = triu(self)
      v = Variable.createFromHandleOne(@(self)self.triu(),self);
    end
    
    function v = repmat(self,varargin)
      v = Variable.createFromHandleOne(@(self,varargin)self.repmat(varargin{:}),self,varargin{:});
    end
    
    function v = sum(self)
      v = Variable.createFromHandleOne(@(self)self.sum(),self);
    end
    
    function v = norm(self,varargin)
      v = Variable.createFromHandleOne(@(self,varargin)norm(self,varargin{:}),self,varargin{:});
    end
    
    function v = inv(self)
      v = Variable.createFromHandleOne(@(self)self.inv(),self);
    end
    
    function v = det(self)
      v = Variable.createFromHandleOne(@(self)self.det(),self);
    end
    
    function v = trace(self)
      v = Variable.createFromHandleOne(@(self)self.trace(),self);
    end
    
    function v = diag(self)
      v = Variable.createFromHandleOne(@(self)self.diag(),self);
    end
    
    function v = abs(self)
      v = Variable.createFromHandleOne(@(self)self.abs(),self);
    end

    function v = sqrt(self)
      v = Variable.createFromHandleOne(@(self)self.sqrt(),self);
    end
    
    function v = sin(self)
      v = Variable.createFromHandleOne(@(self)self.sin(),self);
    end
    
    function v = cos(self)
      v = Variable.createFromHandleOne(@(self)self.cos(),self);
    end
    
    function v = tan(self)
      v = Variable.createFromHandleOne(@(self)self.tan(),self);
    end
    
    function v = atan(self)
      v = Variable.createFromHandleOne(@(self)self.atan(),self);
    end
    
    function v = asin(self)
      v = Variable.createFromHandleOne(@(self)self.asin(),self);
    end
    
    function v = acos(self)
      v = Variable.createFromHandleOne(@(self)self.acos(),self);
    end
    
    function v = tanh(self)
      v = Variable.createFromHandleOne(@(self)self.tanh(),self);
    end
    
    function v = cosh(self)
      v = Variable.createFromHandleOne(@(self)self.cosh(),self);
    end
    
    function v = sinh(self)
      v = Variable.createFromHandleOne(@(self)self.sinh(),self);
    end
    
    function v = atanh(self)
      v = Variable.createFromHandleOne(@(self)self.atanh(),self);
    end
    
    function v = asinh(self)
      v = Variable.createFromHandleOne(@(self)self.asinh(),self);
    end
    
    function v = acosh(self)
      v = Variable.createFromHandleOne(@(self)self.acosh(),self);
    end
    
    function v = exp(self)
      v = Variable.createFromHandleOne(@(self)self.exp(),self);
    end
    
    function v = log(self)
      v = Variable.createFromHandleOne(@(self)self.log(),self);
    end
    
    % two arguments
    function v = mtimes(a,b)
      v = Variable.createFromHandleTwo(@(a,b)a.mtimes(b),a,b);
    end
    
    function v = mpower(a,b)
      v = Variable.createFromHandleTwo(@(a,b)a.mpower(b),a,b);
    end
    
    function v = mldivide(a,b)
      a = Variable.getValue(a);
      b = Variable.getValue(b);
      if (numel(a) > 1) && (numel(b) > 1)
        v = Variable.Matrix(solve(a,b));
      else
        v = Variable.Matrix(mldivide(a,b));
      end
    end
    
    function v = mrdivide(a,b)
      v = Variable.createFromHandleTwo(@(a,b)mrdivide(a,b),a,b);
    end
    
    function v = cross(a,b)
      v = Variable.createFromHandleTwo(@(a,b)a.cross(b),a,b);
    end
    
    function v = dot(a,b)
      v = Variable.createFromHandleTwo(@(a,b)a.dot(b),a,b);
    end
    
    function v = polyval(p,a)
      v = Variable.createFromHandleTwo(@(p,a)polyval(p,a),p,a);
    end
    
    function v = jacobian(ex,arg)
      v = Variable.createFromHandleTwo(@(ex,arg)jacobian(ex,arg),ex,arg);
    end
    
    function v = plus(a,b)
      v = Variable.createFromHandleTwo(@(a,b)plus(a,b),a,b);
    end
    
    function v = minus(a,b)
      v = Variable.createFromHandleTwo(@(a,b)minus(a,b),a,b);
    end
    
    function v = times(a,b)
      v = Variable.createFromHandleTwo(@(a,b)times(a,b),a,b);
    end
    
    function v = power(a,b)
      v = Variable.createFromHandleTwo(@(a,b)power(a,b),a,b);
    end
    
    function v = rdivide(a,b)
      v = Variable.createFromHandleTwo(@(a,b)rdivide(a,b),a,b);
    end
    
    function v = ldivide(a,b)
      v = Variable.createFromHandleTwo(@(a,b)ldivide(a,b),a,b);
    end
    
    function v = atan2(a,b)
      v = Variable.createFromHandleTwo(@(a,b)a.atan2(b),a,b);
    end
    
    % three arguments
    function r = jtimes(ex,arg,v)
      ex = Variable.getValue(ex);
      arg = Variable.getValue(arg);
      v = Variable.getValue(v);
      r = Variable.Matrix(jtimes(ex,arg,v));
    end
    
    % lists
    function v = horzcat(varargin)
      N = numel(varargin);
      outValues = cell(1,N);
      for k=1:numel(varargin)
        outValues{k} = Variable.getValue(varargin{k});
      end    
      v = Variable.Matrix(horzcat(outValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      outValues = cell(1,N);
      for k=1:numel(varargin)
        outValues{k} = Variable.getValue(varargin{k});
      end
      v = Variable.Matrix(vertcat(outValues{:}));
    end
    
    %%% element wise operations
    function n = ppp(self)
      % DO NOT CHANGE THIS FUNCTION!
      % It is automatically renamed for Octave as properties is not 
      % allowed as a function name.
      %
      % Tab completion in Matlab for custom variables
      n = [fieldnames(self);fieldnames(self.type.children)];	
    end
  end
end

