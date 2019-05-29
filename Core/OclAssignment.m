classdef OclAssignment < handle
  
  properties
    varsList
  end
  
  methods
    function self = OclAssignment(varsList)
      self.varsList = varsList;
    end
    
    function varargout = subsref(self,s)
      
      vl = self.varsList;
      
      if length(vl) == 1
        [varargout{1:nargout}] = subsref(vl{1}, s);
      elseif numel(s) == 1 && (strcmp(s.type,'()') || strcmp(s.type,'{}'))
        [varargout{1:nargout}] = subsref(vl{s.subs{:}} ,s(2:end));
      end
      
    end
    
    function disp(self) 
      vs = self.varsList;
      disp('OclAssignment with content:');
      disp('{');
      disp(' ');
      for k=1:length(vs)
        disp(vs{k});
      end
      disp('}');
    end
    
  end
  
end