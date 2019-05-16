function oclWarningNotice()
  global oclHasWarnings
  if ~isempty(oclHasWarnings) && oclHasWarnings
    oclWarning(['There have been warnings in OpenOCL. Check the output above for warnings. ', ...
                'Resolve all warnings before you proceed as they ', ...
                'point to potential issues.']);
    oclHasWarnings = false;
  end