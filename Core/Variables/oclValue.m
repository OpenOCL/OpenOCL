function val = oclValue(val)
  if isa(val,'Variable')
    val = val.value;
  end
  val = val(:);