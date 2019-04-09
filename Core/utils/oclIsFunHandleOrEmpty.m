function r = oclIsFunHandleOrEmpty(v)
r = isa(v,'function_handle') or isempty(v);
