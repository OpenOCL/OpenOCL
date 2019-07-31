classdef Assignment < handle
  
  properties
    varsList
  end
  
  methods
    function self = Assignment(varsList)
      self.varsList = varsList;
    end
    
    function r = length(self)
      r = length(self.varsList);
    end
    
    function varargout = subsref(self,s)
      
      vl = self.varsList;
      
      if (strcmp(s(1).type,'()') || strcmp(s(1).type,'{}'))
        [varargout{1:nargout}] = subsref(vl{s(1).subs{:}}, s(2:end));
      elseif length(vl) == 1
        [varargout{1:nargout}] = subsref(vl{1} ,s);
      else
        oclError('Not supported.');
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