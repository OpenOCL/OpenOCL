classdef CasadiLib
  %CASADILIB Casadi functionality for Vars and Systems
  
  properties

  end
  
  methods(Static)
    
    function setSXSystem(system)
      CasadiLib.setSX(system.state)
      CasadiLib.setSX(system.algVars)
      CasadiLib.setSX(system.controls)
      CasadiLib.setSX(system.parameters)
    end
    
    function setMXSystem(system)
      CasadiLib.setMX(system.state)
      CasadiLib.setMX(system.algVars)
      CasadiLib.setMX(system.controls)
      CasadiLib.setMX(system.parameters)
    end
    
    
    function setSX(var)
      %setSX()
      CasadiLib.setSym(var,'SX')
    end
    
    function setMX(var)
      %setSX()
      CasadiLib.setSym(var,'MX')
    end
    

    function setSym(var,type,varargin)
      % setSX(type)
      %   type is either 'SX' or 'MX'
      % setSX(type,varIndex)
      %   not public only for recursion
      
      assert(isa(var,'Var'), 'Input has to be a Var.');
      
      % variable index is used in the naming of the symbolic variable
      varPrefix = var.id;
      if nargin==4
        varPrefix = varargin{1};
        varIndex = varargin{2};
        
        delimiter = '';
        if ~strcmp(varPrefix,'')
          delimiter = '_';
        end

        varPrefix = [varPrefix delimiter var.id varIndex];
        
      end
      
      
      % create symbolic variable and assign as value if var has no subvars
      if isempty(var.subVars)
        
        if prod(var.size) == 0
          return
        end
        
        if strcmp(type,'MX')
          var.set(casadi.MX.sym(varPrefix,var.size));
        else
          var.set(casadi.SX.sym(varPrefix,var.size));
        end
        return
      end
      
      % go recursively through subvars
      for i = 1:length(var.subVars)
        subVar = var.subVars(i);
        indizes = var.varIds.get(subVar.id);
        
        % find i in indizes
        subIndex = num2str(find(indizes==i));
        if length(indizes)==1
          subIndex = '';
        end
        
        CasadiLib.setSym(subVar,type,varPrefix,subIndex);
      end
      
    end % setSym
    
    
  end
  
end

