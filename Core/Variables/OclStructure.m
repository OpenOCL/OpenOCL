classdef OclStructure < handle
  %OCLSTRUCTURE Abtract class for defining variable structures.
  %   Structures can be trees or matrizes or trajectories
  
  properties
    thisPositions
    thisSize
  end
  
  methods
    function get(varargin)
      % get(id)
      % get(id,slice)
      error('Not Implemented.');
    end
    
    function positions(varargin)
      error('Not Implemented.');
    end
    
    function size(varargin)
      error('Not Implemented.');
    end
    
    function getChildPointers(varargin)
      error('Not Implemented.');
    end
    
    function getWithPositions(varargin)
      error('Not Implemented.');
    end
  end
end

