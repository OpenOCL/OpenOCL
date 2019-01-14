classdef NLPSolver < handle

  properties
    nlp
    timeMeasures

    bounds
    initialBounds
    endBounds
  end
  
  methods
    
    function self = NLPSolver()
      self.timeMeasures = struct;
      
      self.initialBounds = struct;
      self.endBounds = struct;
    end
    
    function solve(~,varargin)
      oclError('Not implemented. Call CasadiNLPSolver instead.');
    end
    
    function initialGuess = getInitialGuess(self)
      igTic = tic;
      
      initialGuess = Variable.create(self.nlp.varsStruct,0);
      
      [lb,ub] = self.getNlpBounds();
      
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
    
    function setParameter(self,id,varargin)
      % setParameter(id,value)
      % setParameter(id,lower,upper)
      self.setBounds(id,varargin{:})
    end
    
    function setBounds(self,id,in3,in4)

      self.bounds.(id) = struct;
      if nargin==3
        self.bounds.(id).lower = in3;
        self.bounds.(id).upper = in3;
      else
        self.bounds.(id).lower = in3;
        self.bounds.(id).upper = in4;
      end
    end
    
    function setInitialBounds(self,id,in3,in4)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.initialBounds.(id) = struct;
      if nargin==3
        self.initialBounds.(id).lower = in3;
        self.initialBounds.(id).upper = in3;
      else
        self.initialBounds.(id).lower = in3;
        self.initialBounds.(id).upper = in4;
      end
    end
    
    function setEndBounds(self,id,in3,in4)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.endBounds.(id) = struct;
      if nargin==3
        self.endBounds.(id).lower = in3;
        self.endBounds.(id).upper = in3;
      else
        self.endBounds.(id).lower = in3;
        self.endBounds.(id).upper = in4;
      end
    end    
    
    function [lowerBounds,upperBounds] = getNlpBounds(self)
      
      boundsStruct = self.nlp.varsStruct.flat();
      lowerBounds = Variable.create(boundsStruct,-inf);
      upperBounds = Variable.create(boundsStruct,inf);
      
      lowerBounds.time.set(0);
      
      % system bounds
      names = fieldnames(self.nlp.system.bounds);
      for i=1:length(names)
        id = names{i};
        lowerBounds.get(id).set(self.nlp.system.bounds.(id).lower);
        upperBounds.get(id).set(self.nlp.system.bounds.(id).upper);
      end
      
      % solver bounds
      names = fieldnames(self.bounds);
      for i=1:length(names)
        id = names{i};
        lowerBounds.get(id).set(self.bounds.(id).lower);
        upperBounds.get(id).set(self.bounds.(id).upper);
      end
      
      % initial bounds
      names = fieldnames(self.initialBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,1).set(self.initialBounds.(id).lower);
        ub(:,:,1).set(self.initialBounds.(id).upper);
      end
      
      % end bounds
      names = fieldnames(self.endBounds);
      for i=1:length(names)
        id = names{i};
        lb = lowerBounds.get(id);
        ub = upperBounds.get(id);
        lb(:,:,end).set(self.endBounds.(id).lower);
        ub(:,:,end).set(self.endBounds.(id).upper);
      end
      
      lowerBounds = lowerBounds.value;
      upperBounds = upperBounds.value;
      
    end
    
    function solutionCallback(self,times,solution)
      self.nlp.system.solutionCallback(times,solution);
    end
    
    
  end
  
end
