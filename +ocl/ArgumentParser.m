classdef ArgumentParser < handle

properties (Constant)
  opt_id = '9kuetrgshwt364759uedhhrytsj$%284' % not set identifier
end

properties
  inputParser

  keywords
  optionals
  parameters
end

methods

  function self = ArgumentParser()
    self.inputParser = inputParser;

    self.keywords = {};
    self.optionals = {};
    self.parameters = {};
  end

  function addOptional(name, default, checkfh)

    assert(isempty(self.keywords) && isempty(self.parameters), 'Optional arguments must be before parameters and keyword arguments.');

    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh;

    self.optionals{end+1} = entry;
  end

  function addKeyword(name, default, checkfh)

    assert(isempty(self.parameters), 'Keyword arguments must be before parameters.');

    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh ;

    self.keywords{end+1} = entry;
  end

  function addParameter(name, default, checkfh)
    entry = struct;
    entry.name = name;
    entry.default = default;
    entry.checkfh = checkfh ;

    self.parameters{end+1} = entry;
  end

  function r = parse(varargin)

    opt_list = self.optionals;
    key_list = self.keyworlds;
    param_list = self.parameters;

    ip = self.inputParser;

    % positional arguments
    for k=1:length(opt_list)
      entry = opt_list{k};
      self.inputParser.addOptional(entry.name, entry.default, entry.checkfh);
    end

    % keyword argument as positional argument
    for k=1:length(key_list)
      entry = key_list{k};
      self.inputParser.addOptional([entry.name,'Optional'], ArgumentParser.opt_id, entry.checkfh || @(el) strcmp(el, ArgumentParser.opt_id));
    end

    % keyword arguments as parameter
    for k=1:length(key_list)
      entry = key_list{k};
      self.inputParser.addParameter(entry.name, entry.default, entry.checkfh);
    end

    % paramter arguments
    for k=1:length(param_list)
      entry = param_list{k};
      self.inputParser.addParameter(entry.name, entry.default, entry.checkfh);
    end

    ip.parse(varargin{:});

    % store parsing results in struct
    r = struct;

    % optionals
    for k=1:length(opt_list)
      name = opt_list{k}.name;
      r.(name) = ip.Results.(name);
    end

    % keywords
    for k=1:length(opt_list)
      name = key_list{k}.name;

      if strcmp(ip.Results.([name,'Optional']), ArgumentParser.opt_id)
        r.(name) = p.Results.(name));
      else
        r.(name) = p.Results.([name,'Optional']));
      end
    end

    % parameters
    for k=1:length(opt_list)
      name = param_list{k}.name;
      r.(name) = ip.Results.(name);
    end

  end

end

end
