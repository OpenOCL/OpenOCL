classdef Expression < Arithmetic
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    thisValue
  end
  
  methods

    function self = Expression(v)
      
      if nargin == 1
        self.setValue(v);
      end
      
    end
    
    function c = copy(self)
      c = Expression(self.value);
    end
    
    function varargout = subsref(self,s)
      if numel(s) == 1 && strcmp(s.type,'()')
        [varargout{1}] = Expression(self.value.subsref(s));
      elseif numel(s) > 1 && strcmp(s(1).type,'()')
        v = Expression(self.value.subsref(s(1)));
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
    
    function v = value(self,sliceOp)
      if nargin==2
        v = self.thisValue(sliceOp{1},sliceOp{2});
      else
        v = self.thisValue;
      end
    end
    
    function setValue(self,v,sliceOp)
      if nargin==3
        self.thisValue(sliceOp{1},sliceOp{2}) = v;
      else
        self.thisValue = v;
      end
    end

  end
  
end

