function websaveProgress(file, url, period, varargin)

arguments = varargin; 

t_filesize = timer('TimerFcn', @(varargin) checkFilesize(file), 'ExecutionMode', 'fixedDelay', 'Period', period);

t_websave = timer('TimerFcn', @(varargin) websaveFunction(file, url, arguments));

start(t_filesize);
start(t_websave);
% websave(file, url, varargin{:});
stop(t_filesize);
stop(t_websave)

end

function websaveFunction(file, url, varargin)
  websave(file, url, varargin{:});
end

function checkFilesize(file)
  file_data = dir(file);
  file_size_mb = file_data.bytes/1024/1024;
  disp(['Downloaded: ', num2str(file_size_mb), ' MB']);
end