function oclWarningNotice()
  global oclHasWarnings
  if ~isempty(oclHasWarnings) && oclHasWarnings
    oclWarning(['There have been warnings in OpenOCL. Resolve all warnings ',...
                'before you proceed as they point to potential issues.']);
    oclHasWarnings = false;
  end