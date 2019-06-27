function setFromNdMatrix(variable, value)

value = permute(value,[2,3,1]);

% value is numeric or casadi
[Np,Mp,Kp] = size(variable.positions);
[Nv,Mv,Kv] = size(value);

if mod(Np,Nv)~=0 || mod(Mp,Mv)~=0 || mod(Kp,Kv)~=0
  oclError('Can not set values to variable. Dimensions do not match.')
end

val = variable.val;
val.val(variable.positions) = repmat(value,Np/Nv,Mp/Mv,Kp/Kv);
