classdef VarStructure < handle
  %VARSTRUCTURE Abtract class for defining variable structures.
  %   Structures can be Trees or Matrizes or a selection of nodes in a tree
  
  properties
    thisSize
  end
  
  methods
    function get(varargin)
      error('Not Implemented.');
    end
    
    function positions(varargin)
      error('Not Implemented.');
    end
    
    function size(varargin)
      error('Not Implemented.');
    end
  end
  
end

