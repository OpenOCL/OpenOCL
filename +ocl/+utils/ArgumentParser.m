classdef ArgumentParser < handle

properties (Constant)
  opt_id = '9kuetrgshwt364759uedhhrytsj$%284' % not set identifier
end

properties

  requireds
  optionals
  keywords
  parameters
end

methods

  function self = ArgumentParser()
    
    self.requireds = {};
    self.optionals = {};
    self.keywords = {};
    self.parameters = {};
  end
  
  function addRequired(self, name, checkfh)
    assert(isempty(self.optionals) && isempty(self.keywords) && isempty(self.parameters), ...
      'Required arguments must come first, before positional arguments, keyword arguments, and parameters.');
    
    entry = struct;
    entry.name = name;
    entry.checkfh = checkfh;

    self.requireds{end+1} = entry;
    
  end

  function addOptional(self, name, default, checkfh)

    assert(isempty(self.keywords) && isempty(self.parameters), ...
      'Optional arguments must be before keyword arguments and parameters.');

    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh;

    self.optionals{end+1} = entry;
  end

  function addKeyword(self, name, default, checkfh)

    assert(isempty(self.parameters), 'Keyword arguments must be before parameters.');

    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh ;

    self.keywords{end+1} = entry;
  end

  function addParameter(self, name, default, checkfh)
    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh ;

    self.parameters{end+1} = entry;
  end

  function r = parse(self,varargin)

    req_list = self.requireds;
    opt_list = self.optionals;
    key_list = self.keywords;
    param_list = self.parameters;

    ip = inputParser;
    
    % required arguments
    for k=1:length(req_list)
      entry = req_list{k};
      ip.addRequired(entry.name, entry.checkfh);
    end
    
    % positional arguments
    for k=1:length(opt_list)
      entry = opt_list{k};
      ip.addOptional(entry.name, entry.default, entry.checkfh);
    end

    % keyword argument as positional argument
    for k=1:length(key_list)
      entry = key_list{k};
      ip.addOptional([entry.name,'Optional'], self.opt_id, @(el) entry.checkfh(el) || strcmp(el, self.opt_id));
    end

    % keyword arguments as parameter
    for k=1:length(key_list)
      entry = key_list{k};
      ip.addParameter(entry.name, entry.default, entry.checkfh);
    end

    % paramter arguments
    for k=1:length(param_list)
      entry = param_list{k};
      ip.addParameter(entry.name, entry.default, entry.checkfh);
    end

    ip.parse(varargin{:});

    % store parsing results in struct
    r = struct;
    
    % required
    for k=1:length(req_list)
      name = req_list{k}.name;
      r.(name) = ip.Results.(name);
    end

    % optionals
    for k=1:length(opt_list)
      name = opt_list{k}.name;
      r.(name) = ip.Results.(name);
    end

    % keywords
    for k=1:length(key_list)
      name = key_list{k}.name;

      if strcmp(ip.Results.([name,'Optional']), self.opt_id)
        r.(name) = ip.Results.(name);
      else
        r.(name) = ip.Results.([name,'Optional']);
      end
    end

    % parameters
    for k=1:length(param_list)
      name = param_list{k}.name;
      r.(name) = ip.Results.(name);
    end

  end

end

end
