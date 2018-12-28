classdef OclStructure < handle
  %OCLSTRUCTURE Abtract class for defining variable structures.
  %   Structures can be trees or matrizes or trajectories
  properties
    positions
  end
  
  methods
    function o,p = get(varargin)
      % obj,pos = get(id)
      % obj,pos = get(id,slice)
      error('Not Implemented.');
    end
    
    function size(varargin)
      error('Not Implemented.');
    end
  end % methods
  
  methods (Static)
    function pOut = merge(p1,p2)
      % merge(p1,p2)
      % Merge arrays of positions
      % p2 are relative to p1
      % Returns: absolute p2
      np2 = length(p2);
      pOut = cell(1,np2*length(p1));
      i = 1;
      for l=1:length(p1)
        thisP1 = p1{l};
        for k=1:np2
          p = p2{k};
          pOut{i} = thisP1(p);
          i = i+1;
        end
      end      
    end % merge
  end % methods (Static)
end % classdef

