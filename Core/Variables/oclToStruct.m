function r = oclToStruct(tensor)
  r = tensor.type.toStruct(tensor.val);
end