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
      % Merge arrays of positions
      % p2 are relative to p1
      % Returns: absolute p2
      if isnumeric(p1) && isnumeric(p2)
        pout = p1(p2);
      else
        if(isnumeric(p1)) p1={p1};end
        pout = cell(1,length(p2)*length(p1));
        i = 1;
        for l=1:length(p1)
          ap1 = p1{l};
          for k=1:length(p2)
            pout{i} = ap1(p2{k});
            i = i+1;
          end
        end    
      end
    end % merge
    
  end % methods (Static)
end % classdef

