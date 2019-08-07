function vout = toNdMatrix(variable)
ocl.utils.assert(isa(variable, 'ocl.Variable'));   
p = variable.positions;
vout = zeros(size(p,3), size(p,1), size(p,2));
for k=1:size(p,3)
  vout(k,:,:) = reshape(variable.val.val(p(:,:,k)),size(p(:,:,k)));
end
if size(vout,1)==1
  vout = vout(1,:,:);
end