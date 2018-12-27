classdef VarStructure < handle
  %VARSTRUCTURE Abtract class for defining variable structures.
  %   Structures can be Trees or Matrizes or a selection of nodes in a tree
  
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
    
    function parseGetInputs(varargin)
      % r = get(self,id)
      % r = get(self,id,index)
      % r = get(self,index)
      % r = get(self,row,col)
      
      function t = isAllOperator(in)
        t = strcmp(in,'all') || strcmp(in,':');
        if t
          in = ':';
        end
      end
      
      if ischar(varargin{1})
        id = varargin{1};
      end
      
      
      
      
      
    end
    
  end
  
end

