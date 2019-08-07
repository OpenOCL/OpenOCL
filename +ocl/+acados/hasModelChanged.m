function r = hasModelChanged(fh_list, N)

cur_model_datenum = getenv('OCL_MODEL_DATENUM');
cur_model_N = getenv('OCL_MODEL_N');

if isempty(cur_model_datenum) || isempty(cur_model_N) || ...
    str2double(cur_model_N) ~= N
  r = true;
else
  cur_model_datenum = str2double(cur_model_datenum);
  r = false;

  for k=1:length(fh_list)
    info = functions(fh_list{k});

    if strcmp(info.type, 'simple')

      % check function file
      fun_str = info.function;
      file_str = which(fun_str);

      file_info = dir(file_str);

      if file_info.datenum > cur_model_datenum
        r = true;
        break;
      end
    elseif ~strcmp(info.type, 'classsimple')
      r = true;
      break;
    end
  end
end