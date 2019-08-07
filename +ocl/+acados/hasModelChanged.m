function r = hasModelChanged(fh_list)

cur_model_datenum = getenv('OCL_MODEL_DATENUM');
if isempty(cur_model_datenum)
  r = false;
  return;
end

cur_model_datenum = str2double(cur_model_datenum);

r = false;

for k=1:length(fh_list)
  info = functions(fh_list{k});
  
  if ~strcmp(info.type, 'simple') && ~strcmp(info.type, 'anonymous')
    r = true;
    return;
  elseif strcmp(info.type, 'anonymous')
    file_info = dir(info.file);
    if file_info.datenum > cur_model_datenum
      r = true;
      return;
    end
  else
    % check function file
    fun_str = info.function;
    file_str = which(fun_str);
    
    file_info = dir(file_str);
    
    if file_info.datenum > cur_model_datenum
      r = true;
      return;
    end
  end
end

