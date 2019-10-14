function expr = structToSym(ocl_struct, casadi_sym, name_suffix)

if nargin < 3
  name_suffix = '';
end

var_names = fieldnames(ocl_struct.children);
sym_list = cell(length(var_names), 1);
for j = 1:length(var_names)
  id = var_names{j};
  s = ocl_struct.children.(id).type.msize;
  var_sym = casadi_sym([id,name_suffix], s);
  sym_list{j} = var_sym(:);
end
expr = vertcat(sym_list{:});