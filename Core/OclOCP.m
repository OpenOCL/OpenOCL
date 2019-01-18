classdef OclOCP < handle
  %OCLOCP Optimal Control Problem formulation
  %   Derive from this class to formulate an optimal control problem by
  %   implementing the abstract methods.

  properties (Access = public)
    fh
  end
  
  methods(Access = public)
    function self = OclOCP(pcH,acH,pconH,bcH,dcH)
      if nargin==1 && (isa(pcH,'OclSystem') || isa(pcH,'System'))
        oclDeprecation('Passing a system to the constructor of OclOCP is deprecated.');
      end
      
      
      
      
      self.fh.pcH   = @(varargin)self.pathCosts(varargin{:});
      self.fh.acH   = @(varargin)self.arrivalCosts(varargin{:});
      self.fh.pconH = @(varargin)self.pathConstraints(varargin{:});
      self.fh.bcH   = @(varargin)self.boundaryConditions(varargin{:});
      self.fh.dcH   = @(varargin)self.discreteCosts(varargin{:});
      if nargin>=1 && ~isempty(pcH)
        self.fh.pcH   = pcH;
      end
      if nargin>=2 && ~isempty(acH)
        self.fh.acH   = acH;
      end
      if nargin>=3 && ~isempty(pconH)
        self.fh.pconH = pconH;
      end
      if nargin>=4 && ~isempty(bcH)
        self.fh.bcH   = bcH;
      end
      if nargin>=5 && ~isempty(dcH)
        self.fh.dcH   = dcH;
      end
    end
  end
  
  methods (Static)
    %%% overridable methods
    function pathCosts(~,~,~,~,~,~,~)
      % pathCosts(self,states,algVars,controls,time,endTime,parameters)
    end
    function arrivalCosts(~,~,~,~)
      % arrivalCosts(self,states,endTime,parameters)
    end
    function pathConstraints(~,~,~,~)
      % pathConstraints(self,states,time,parameters)
    end
    function boundaryConditions(~,~,~,~)
      % boundaryConditions(self,initialStates,finalStates,parameters)
    end
    function discreteCosts(~,~)
      % discreteCost(self,vars)
    end
  end
end

