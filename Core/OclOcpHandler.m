
classdef OclOcpHandler < handle
  properties (Access = public)
    pathCostsFun
    arrivalCostsFun
    boundaryConditionsFun
    pathConstraintsFun
    discreteCostsFun
    
    bounds
    initialBounds
    endBounds
    
    T
    
    options
  end
  
  properties(Access = private)
    ocp    
    system
    nlpVarsStruct
  end

  methods
    function self = OclOcpHandler(T,system,ocp,options)
      self.ocp = ocp;
      self.system = system;
      self.options = options;
      self.T = T;
      
      N = options.nlp.controlIntervals;
      
      self.bounds = struct;
      self.initialBounds = struct;
      self.endBounds = struct;
      
      if length(T) == 1
        hControlsNormalized = 1/N;
      elseif length(T) == N+1
        hControlsNormalized = (T(2:N+1)-T(1:N)) / T(end);
        T = T(end);
      elseif length(T) == N
        hControlsNormalized = T/sum(T);
        T = sum(T);
      elseif isempty(T)
        hControlsNormalized = 1/N;
        T = [];
      else
        oclError('Dimension of T does not match the number of control intervals.')
      end
      
      self.setBounds('h_normalized',hControlsNormalized);
      if ~isempty(T)
        self.setBounds('T',T)
      end
      
    end
    
    function setup(self)
      % variable sizes
      
      self.system.addControl('h_normalized');
      self.system.addParameter('T');
      
      self.system.setup();
      
      sx = self.system.statesStruct.size();
      sz = self.system.algVarsStruct.size();
      su = self.system.controlsStruct.size();
      sp = self.system.parametersStruct.size();

      fhPC = @(self,varargin) self.getPathCosts(varargin{:});
      self.pathCostsFun = OclFunction(self, fhPC, {sx,sz,su,sp}, 1);
      
      fhAC = @(self,varargin) self.getArrivalCosts(varargin{:});
      self.arrivalCostsFun = OclFunction(self, fhAC, {sx,sp}, 1);
      
      fhBC = @(self,varargin)self.getBoundaryConditions(varargin{:});
      self.boundaryConditionsFun = OclFunction(self, fhBC, {sx,sx,sp}, 3);
      
      fhPConst = @(self,varargin)self.getPathConstraints(varargin{:});
      self.pathConstraintsFun = OclFunction(self, fhPConst, {sx,sp}, 3);
    end
    
    function setNlpVarsStruct(self,varsStruct)
      self.nlpVarsStruct = varsStruct;
      sv = varsStruct.size;
      fhDC = @(self,varargin)self.getDiscreteCosts(varargin{:});
      self.discreteCostsFun = OclFunction(self, fhDC, {sv}, 1);
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
    
    function addParameter(self,varargin)
      % addParameter(id)
      % addParameter(id,size)
      self.system.parametersStruct.add(varargin{:});
    end
    
    function r = getPathCosts(self,x,z,u,p)
      pcHandler = OclCost(self.ocp);
      
      if self.options.controls_regularization
        pcHandler.add(self.options.controls_regularization_value*(u.'*u));
      end
      
      x = OclTensor.create(self.system.statesStruct,x);
      z = OclTensor.create(self.system.algVarsStruct,z);
      u = OclTensor.create(self.system.controlsStruct,u);
      p = OclTensor.create(self.system.parametersStruct,p);
      
      self.ocp.fh.pathCosts(pcHandler,x,z,u,p);
      r = pcHandler.value;
    end
    
    function r = getArrivalCosts(self,x,p)
      acHandler = OclCost(self.ocp);
      x = OclTensor.create(self.system.statesStruct,x);
      p = OclTensor.create(self.system.parametersStruct,p);
      
      self.ocp.fh.arrivalCosts(acHandler,x,p);
      r = acHandler.value;
    end
    
    function [val,lb,ub] = getPathConstraints(self,x,p)
      pathConstraintHandler = OclConstraint(self.ocp);
      x = OclTensor.create(self.system.statesStruct,x);
      p = OclTensor.create(self.system.parametersStruct,p);
      
      self.ocp.fh.pathConstraints(pathConstraintHandler,x,p);
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,x0,xF,p)
      bcHandler = OclConstraint(self.ocp);
      x0 = OclTensor.create(self.system.statesStruct,x0);
      xF = OclTensor.create(self.system.statesStruct,xF);
      p = OclTensor.create(self.system.parametersStruct,p);
      
      self.ocp.fh.boundaryConditions(bcHandler,x0,xF,p);
      val = bcHandler.values;
      lb = bcHandler.lowerBounds;
      ub = bcHandler.upperBounds;
    end
    
    function r = getDiscreteCosts(self,v)
      dcHandler = OclCost(self.ocp);
      v = OclTensor.create(self.nlpVarsStruct,v);
      self.ocp.fh.discreteCosts(dcHandler,v);
      r = dcHandler.value;
    end

  end
end

