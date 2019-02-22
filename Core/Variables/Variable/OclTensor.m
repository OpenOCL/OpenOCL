classdef OclTensor < handle
    % OCLTENSOR Default implementation of arithemtic operations for
    % variables
    % This class can be derived from to implement new arithemtics for 
    % variables e.g. casadi variables, or symbolic variables.
    
  properties (Constant)
      MAX_DISP_LENGTH = 200
      DISP_FLOAT_PREC = 6;
   end
  
  properties
    valueStorage
    type
  end
  
  methods (Static)
    
    %%% factory methods
    function tensor = create(rn,value) 
      vs = OclValueStorage.allocate(value,numel(rn));
      vs.set(rn,value);
      tensor = OclTensor.construct(rn,vs);
    end
    
    function tensor = construct(rn,vs)
      if isnumeric(vs.storage)
        tensor = OclTensor(rn,vs);
      elseif isa(vs.storage,'casadi.MX') || isa(vs.storage,'casadi.SX')
        tensor = CasadiTensor(rn,isa(vs.storage,'casadi.MX'),vs);
      else
        oclError('Not implemented for this type of variable.')
      end
    end

    function tensor = Matrix(value)
      % obj = Matrix(input,val)
      tr = OclRootNode(struct,size(value),{1:numel(value)});
      vs = OclValueStorage.allocate(value,numel(value));
      vs.set(tr,value);
      tensor = OclTensor.construct(tr,vs);
    end
    
    function v = createFromHandleOne(fh, a, varargin)
      a = OclTensor.getValue(a);
      v = OclTensor.Matrix( fh(a, varargin{:}) );
    end
    
    function v = createFromHandleTwo(fh, a, b, varargin)
      a = OclTensor.getValue(a);
      b = OclTensor.getValue(b);
      if isnumeric(a) && ((isa(b,'casadi.SX')||isa(b,'casadi.MX')))
        a = casadi.DM(a);  
      end
      v = OclTensor.Matrix(fh(a,b,varargin{:}));
    end
    %%% end factory methods   
    
    function val = getValue(val)
      if isa(val,'OclTensor')
        val = val.value;
      end
    end
    
    function val = getValueAsColumn(val)
      val = OclTensor.getValue(val);
      val = val(:);
    end
    
  end % methods(static)
  
  methods
    function self = OclTensor(type,val)
      narginchk(2,2);
      assert(isa(type,'OclRootNode'));
      assert(isa(val,'OclValueStorage'));
      self.type = type;
      self.valueStorage = val;
    end
    
    function r = str(self,valueStr)
      if nargin==1
        value = self.value;
        if isnumeric(value)
          valueStr = mat2str(value,OclTensor.DISP_FLOAT_PREC);
        else
          % cell array
          cell2str = cellfun(@(v)[mat2str(v),','],value, 'UniformOutput',false);
          str_joined = strjoin(cell2str);
          valueStr = ['{', str_joined(1:end-1), '}'];
        end
      end
      
      dotsStr = '';
      if numel(valueStr) >= OclTensor.MAX_DISP_LENGTH 
        valueStr = valueStr(1:OclTensor.MAX_DISP_LENGTH);
        dotsStr = '...';
      end
      
      childrenString = '  Branches: None\n';
      if self.type.hasBranches()
        cArray = cell(1, length(fieldnames(self.type.branches)));
        names = fieldnames(self.type.branches);
        for i=1:length(names)-1
          cArray{i} = [names{i}, ', '];
        end
        cArray{end} = names{end};
        childrenString = ['  Branches: ', cArray{:}, '\n'];
      end
      
      r = sprintf([ ...
                   class(self), ':\n' ....
                   '  Size: ', mat2str(self.size()), '\n' ....
                   '  Type: ', class(self.type), '\n' ...
                   childrenString, ...
                   '  Value: ', valueStr, dotsStr, '\n' ...
                   ]);
    end
    
    function disp(self)
      disp(self.str());
    end

    function varargout = subsref(self,s)
      % v(1)
      % v.x
      % v.val
      % v.set(4)
      % v.dot(w)
      % ...
      
      if numel(s) == 1 && strcmp(s.type,'()')
        % v(1)
        [varargout{1}] = self.slice(s.subs{:});
      elseif numel(s) > 1 && strcmp(s(1).type,'()')
        % v(1).something().a
        v = self.slice(s(1).subs{:});
        [varargout{1:nargout}] = subsref(v,s(2:end));
      elseif numel(s) > 0 && strcmp(s(1).type,'.')
        % v.something or v.something()
        id = s(1).subs;
        if isa(self.type,'OclRootNode') && isfield(self.type.branches,id) && numel(s) == 1
          % v.x
          [varargout{1}] = self.get(id);
        elseif isa(self.type,'OclRootNode') && isfield(self.type.branches,id)
          % v.x.get(3).set(2).val || v.x.y.get(1)
          v = self.get(id);
          [varargout{1:nargout}] = subsref(v,s(2:end));
        else
          % v.slice(1) || v.get(id)
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
      % v.val(1) = 1
      % v* = OclTensor
      if numel(s)==1 && strcmp(s(1).type,'.') && ~isfield(self.type.branches,s(1).subs)
        self = builtin('subsasgn',self,s,v);
      else
        v = OclTensor.getValue(v);
        subVar = subsref(self,s);
        subVar.set(v);
      end
    end
    
    % TODO: test	
    function n = numArgumentsFromSubscript(~,~,~)	
      n=1;
    end	

    %%% delegate methods to OclValueStorage
    function set(self,val)
      % set(val)
      % set(val,slice1,slice2,slice3)
      self.valueStorage.set(self.type,val)
    end
    function v = value(self)
      v = self.valueStorage.value(self.type);
    end
    %%%
    
    %%% delegate methods to type
    function s = size(self)
      s = self.type.size;    
    end
    
    function r = get(self,id)
      % r = get(id)
      child = self.type.get(id);
      r = OclTensor.construct(child,self.valueStorage);
    end
    
    function r = slice(self,varargin)
      % r = slice(dim1,[dim2],[dim3])
      idz = reshape([self.type.indizes{:}],self.type.size);
      idz = idz(varargin{:});
      shape = size(idz);
      
      m = OclRootNode(struct,shape,{idz(:)}); 
      r = OclTensor.construct(m,self.valueStorage);
    end
    %%%
    
    function ind = end(self,k,n)
       szd = self.type.size;
       if k < n
          ind = szd(k);
       else
          ind = prod(szd(k:end));
       end
    end

    function y = linspace(d1,d2,n)
      n1 = n-1;
      y = d1 + (0:n1).*(d2 - d1)/n1;
    end
    
    %%% operators
    % single argument
    function v = uplus(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)uplus(self),self);
    end
    function v = uminus(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)uminus(self),self);
    end
   
    function v = ctranspose(self)
      oclWarning(['Complex transpose is not defined. Using matrix transpose ', ...
                  'instead. Use the .'' operator instead on the '' operator!']);
      v = self.transpose();
    end
    function v = transpose(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)transpose(self),self);
    end
    
    function v = reshape(self,varargin)
      v = OclTensor.createFromHandleOne(@(self,varargin)reshape(self,varargin{:}),self,varargin{:});
    end
    
    function v = triu(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)triu(self),self);
    end
    
    function v = repmat(self,varargin)
      v = OclTensor.createFromHandleOne(@(self,varargin)repmat(self,varargin{:}),self,varargin{:});
    end
    
    function v = sum(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)sum(self),self);
    end
    
    function v = norm(self,varargin)
      v = OclTensor.createFromHandleOne(@(self,varargin)norm(self,varargin{:}),self,varargin{:});
    end
    
    function v = inv(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)inv(self),self);
    end
    
    function v = det(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)det(self),self);
    end
    
    function v = trace(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)trace(self),self);
    end
    
    function v = diag(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)diag(self),self);
    end
    
    function v = abs(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)abs(self),self);
    end

    function v = sqrt(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)sqrt(self),self);
    end
    
    function v = sin(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)sin(self),self);
    end
    
    function v = cos(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)cos(self),self);
    end
    
    function v = tan(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)tan(self),self);
    end
    
    function v = atan(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)atan(self),self);
    end
    
    function v = asin(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)asin(self),self);
    end
    
    function v = acos(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)acos(self),self);
    end
    
    function v = tanh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)tanh(self),self);
    end
    
    function v = cosh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)cosh(self),self);
    end
    
    function v = sinh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)sinh(self),self);
    end
    
    function v = atanh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)atanh(self),self);
    end
    
    function v = asinh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)asinh(self),self);
    end
    
    function v = acosh(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)acosh(self),self);
    end
    
    function v = exp(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)exp(self),self);
    end
    
    function v = log(self)
      v = OclTensor.createFromHandleOne(@(self,varargin)log(self),self);
    end
    
    % two arguments
    function v = mtimes(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)mtimes(a,b),a,b);
    end
    
    function v = mpower(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)mpower(a,b),a,b);
    end
    
    function v = mldivide(a,b)
      a = OclTensor.getValue(a);
      b = OclTensor.getValue(b);
      if (numel(a) > 1) && (numel(b) > 1)
        v = OclTensor.Matrix(solve(a,b));
      else
        v = OclTensor.Matrix(mldivide(a,b));
      end
    end
    
    function v = mrdivide(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)mrdivide(a,b),a,b);
    end
    
    function v = cross(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)cross(a,b),a,b);
    end
    
    function v = dot(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)dot(a,b),a,b);
    end
    
    function v = polyval(p,a)
      v = OclTensor.createFromHandleTwo(@(p,a,varargin)polyval(p,a),p,a);
    end
    
    function v = jacobian(ex,arg)
      v = OclTensor.createFromHandleTwo(@(ex,arg,varargin)jacobian(ex,arg),ex,arg);
    end
    
    function v = plus(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)plus(a,b),a,b);
    end
    
    function v = minus(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)minus(a,b),a,b);
    end
    
    function v = times(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)times(a,b),a,b);
    end
    
    function v = power(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)power(a,b),a,b);
    end
    
    function v = rdivide(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)rdivide(a,b),a,b);
    end
    
    function v = ldivide(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)ldivide(a,b),a,b);
    end
    
    function v = atan2(a,b)
      v = OclTensor.createFromHandleTwo(@(a,b,varargin)atan2(a,b),a,b);
    end
    
    % three arguments
    function r = jtimes(ex,arg,v)
      ex = OclTensor.getValue(ex);
      arg = OclTensor.getValue(arg);
      v = OclTensor.getValue(v);
      r = OclTensor.Matrix(jtimes(ex,arg,v));
    end
    
    % lists
    function v = horzcat(varargin)
      N = numel(varargin);
      outValues = cell(1,N);
      for k=1:numel(varargin)
        outValues{k} = OclTensor.getValue(varargin{k});
      end    
      v = OclTensor.Matrix(horzcat(outValues{:}));
    end
    
    function v = vertcat(varargin)
      N = numel(varargin);
      outValues = cell(1,N);
      for k=1:numel(varargin)
        outValues{k} = OclTensor.getValue(varargin{k});
      end
      v = OclTensor.Matrix(vertcat(outValues{:}));
    end
    
    %%% element wise operations
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

