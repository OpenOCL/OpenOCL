function checkStartup()
  persistent been_here
  if isempty(been_here) || ~been_here
    disp('Running OpenOCL setup procedure. This may required your input, and may take a while at the first time.')
    StartupOCL
    been_here = true;
  end
end