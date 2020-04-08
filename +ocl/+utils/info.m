% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function info(msg)

N = 60; % max line width
  
l = length(msg);
d = floor(l/N);

new_msg = '';
offset = 0;
for k=1:d
  
  msg_part = msg( (k-1)*N+1 : k*N);
  spaces = strfind(msg_part, ' ');
  
  new_offset = N - spaces(end);
  new_msg = sprintf('%s %s %s', new_msg, msg( (k-1)*N-offset+1 : k*N-new_offset), ocl.utils.newline);
  offset = new_offset;
end
fprintf('%s %s %s', new_msg, msg( d*N-offset+1 : end), ocl.utils.newline);

