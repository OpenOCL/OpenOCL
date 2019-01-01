classdef NLPSolver < handle
  
  properties
    nlp
  end
  
  methods
    
    function self = NLPSolver()
    end
    
    function r = getInitialGuess(self,varargin)
      r = self.nlp.getInitialGuess(varargin{:});
    end
    
    function setBounds(self,varargin)
      self.nlp.setBounds(varargin{:})
    end
    
    function setParameter(self,varargin)
      self.nlp.setParameter(varargin{:})
    end
    
    function setInitialBounds(self,varargin)
      self.nlp.setInitialBounds(varargin{:})
    end
    
    function setEndBounds(self,varargin)
      self.nlp.setEndBounds(varargin{:})
    end
    
    
  end
  
end