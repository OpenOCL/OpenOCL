% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Structure < handle
  % OCLSTRUCTURE Basic datatype represent variables in a tree like structure.
  %
  properties
    children
    len
  end

  methods
    function self = Structure()
      % ocl.types.Structure()
      narginchk(0,0);
      self.children = struct;
      self.len = 0;
    end
    
    function r = getNames(self)
      r = fieldnames(self.children);
    end

    function add(self,id,in2)
      % add(id)
      % add(id,length)
      % add(id,size)
      % add(id,obj)
      if nargin==2
        % add(id)
        N = 1;
        M = 1;
        obj = ocl.types.Matrix([N,M]);
      elseif isnumeric(in2) && length(in2) == 1
        % args:(id,length)
        N = in2;
        M = 1;
        obj = ocl.types.Matrix([N,M]);
      elseif isnumeric(in2)
        % args:(id,size)
        N = in2(1);
        M = in2(2);
        obj = ocl.types.Matrix([N,M]);
      else
        % args:(id,obj)
        [N,M] = in2.size;
        obj = in2;
      end
      pos = self.len+1:self.len+N*M;
      pos = reshape(pos,N*M,1);
      self.addObject(id,obj,pos);
    end
    
    function addRepeated(self,names,arr,N)
      % addRepeated(self,arr,N)
      %   Adds repeatedly a list of structure objects
      %     e.g. ocpVar.addRepeated([stateStructure,controlStructure],20);
      for i=1:N
        for j=1:length(arr)
          self.add(names{j},arr{j})
        end
      end
    end
    
    function addObject(self,id,obj,pos)
      % addVar(id, obj)
      %   Adds a structure object
      
      N = length(pos);
      self.len = self.len+N;
      
      if ~isfield(self.children, id)
        self.children.(id).type = obj;
        self.children.(id).positions = pos;
      else
        self.children.(id).positions(:,end+1) = pos;
      end
    end
    
    function [t,p] = get(self,id,pos)
      % get(pos,id)
      if nargin==2
        pos = (1:self.len).';
      end
      p = self.children.(id).positions;
      t = self.children.(id).type;
      p = self.merge(pos,p);
    end
    
    function r = length(self)
      r = self.len;
    end
    
    function [N,M] = size(self)
      if nargout>1
        N = self.len;
        M = 1;
      else
        N = [self.len,1];
      end
    end

    function pout = merge(~,p1,p2)
      % merge(p1,p2)
      % Combine arrays of positions on the second dimension
      % p2 are relative to p1
      % Returns: absolute p2
      [~,K1] = size(p1);
      [N2,K2] = size(p2);
      
      pout = zeros(N2,K1*K2);
      for k=1:K1
       ap1 = p1(:,k);
       for l=1:K2
         pout(:,l+(k-1)*K2) = ap1(p2(:,l));
       end
      end
    end % merge
    
  end % methods
end % class



