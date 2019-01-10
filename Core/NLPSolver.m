classdef NLPSolver < handle
  
  properties
    nlp
    timeMeasures
  end
  
  methods
    
    function self = NLPSolver()
      self.timeMeasures = struct;
    end
    
    function solutionCallback(self,times,solution)
      self.nlp.system.solutionCallback(times,solution);
    end
    
    function r = getInitialGuess(self,varargin)
      igTic = tic;
      r = self.nlp.getInitialGuess(varargin{:});
      self.timeMeasures.initialGuess = toc(igTic);
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