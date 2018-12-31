classdef OclStructure < handle
  %OCLSTRUCTURE Abtract class for defining variable structures.
  %   Structures can be trees or matrizes or trajectories
  properties
  end
  
  methods
    function get(varargin)
      % r = get(id)
      % r = get(id,slice)
      error('Not Implemented.');
    end
    
    function size(varargin)
      error('Not Implemented.');
    end
    
    function getPositions(varargin)
      error('Not Implemented.');
    end
    
  end % methods
  
  methods (Static)
  
    function pout = merge(p1,p2)
      % merge(p1,p2)
      % Combine arrays of positions on the third dimension
      % p2 are relative to p1
      % Returns: absolute p2
      [~,~,K1] = size(p1);
      [N2,M2,K2] = size(p2);
      
      pout = zeros(N2,M2,K1*K2);
      for k=1:K1
       ap1 =  p1(:,:,k);
       pout(:,:,(k-1)*K2+1:k*K2) = ap1(p2);
      end
    end % merge
    
  end % methods (Static)
end % classdef

