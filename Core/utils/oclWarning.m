function oclWarning(msg)
  warning(msg)
  global oclHasWarnings
  oclHasWarnings = true;