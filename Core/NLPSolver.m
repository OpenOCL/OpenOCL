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
    
    function initialGuess = getInitialGuess(self)
      igTic = tic;
      
      initialGuess = NlpValues.create(self.nlp.varsStruct,0);
      
      [lb,ub] = self.nlp.getNlpBounds();
      
      guessValues = (lb + ub) / 2;
      
      % set to lowerBounds if upperBounds are inf
      indizes = isinf(ub);
      guessValues(indizes) = lb(indizes);
      
      % set to upperBounds of lowerBounds are inf
      indizes = isinf(lb);
      guessValues(indizes) = ub(indizes);
      
      % set to zero if both lower and upper bounds are inf
      indizes = isinf(lb) & isinf(ub);
      guessValues(indizes) = 0;

      initialGuess.set(guessValues);
      
      self.timeMeasures.initialGuess = toc(igTic);
    end
    
    function setParameter(self,varargin)
      % setParameter(id,value)
      % setParameter(id,lower,upper)
      self.nlp.setBounds(varargin{:})
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
