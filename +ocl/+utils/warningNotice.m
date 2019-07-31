% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function warningNotice()
  global oclHasWarnings
  if ~isempty(oclHasWarnings) && oclHasWarnings
    ocl.utils.warning(['There have been warnings in OpenOCL. Check the output above for warnings. ', ...
                'Resolve all warnings before you proceed as they ', ...
                'point to potential issues.']);
    oclHasWarnings = false;
  end