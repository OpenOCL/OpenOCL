function r = oclIsFunHandleOrEmpty(v)
r = isa(v,'function_handle') || isempty(v);
