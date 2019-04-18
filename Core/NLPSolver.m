classdef NLPSolver < handle

  properties
    nlp
    timeMeasures
  end
  
  methods
    
    function self = NLPSolver()
      self.timeMeasures = struct;
    end
    
    function solve(~,varargin)
      oclError('Not implemented. Call CasadiNLPSolver instead.');
    end
    
    function ig = getInitialGuess(self)
      igTic = tic;
      ig = self.nlp.getInitialGuess();
      self.timeMeasures.initialGuess = toc(igTic);
    end
    
    function setParameter(self,varargin)
      % setParameter(id,value)
      % setParameter(id,lower,upper)
      self.nlp.setInitialBounds(varargin{:})
    end
    
    function setBounds(self,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.nlp.setBounds(varargin{:})
    end
    
    function setInitialBounds(self,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.nlp.setInitialBounds(varargin{:})
    end
    
    function setEndBounds(self,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.nlp.setEndBounds(varargin{:})
    end    
    
    function solutionCallback(self,times,solution)
      self.nlp.system.solutionCallback(times,solution);
    end
    
  end
end
