% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function variable

% small number of numeric value comparison
mx = false;
eps = 1e-5;

v1 = [5;2.8;2];
v2 = [1,5.01,3;6,5,4];

%%% constructor
a1 = ocl.casadi.CasadiVariable.Matrix([3,1],mx);
a2 = ocl.casadi.CasadiVariable.Matrix([2,3],mx);
s1 = a1.value;
s2 = a2.value;

f = casadi.Function('f',{s1},{s1});
assert(isequal(full(f(v1)),v1))
f = casadi.Function('f',{s2},{s2});
assert(isequal(full(f(v2)),v2))

%%% horzcat, vertcat, subsref
aTest = [a1,a1,a1;a2];
aTest = aTest(3:5,2);
vTest = [v1,v1,v1;v2];
vTest = vTest(3:5,2);
f = casadi.Function('f',{s1,s2},{aTest(2:3).value});
assert(isequal(full(f(v1,v2)),vTest(2:3)))

%%% subsasgn
aTest(2:3) = 11;
vTest(2:3) = 11;
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% norm
aTest = norm(aTest);
vTest = norm(vTest);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% uplus, uminus
%aTest = -+(+aTest);
%vTest = -+(+vTest);
%f = casadi.Function('f',{s1,s2},{aTest.value});
%assert(isequal(full(f(v1,v2)),vTest))

%%% sum
aTest = [a1,a1,a1;a2];
aTest = sum(aTest);
vTest = [v1,v1,v1;v2];
vTest = sum(vTest);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% mtimes
aTest = [a1,a1,a1;a2] * 4 * s1 * [2,3,4];
vTest = [v1,v1,v1;v2] * 4 * v1 * [2,3,4];
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% transpose
aTest = aTest.';
vTest = vTest.';
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% reshape
aTest = reshape(aTest,15,1);
vTest = reshape(vTest,15,1);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))
aTest = reshape(aTest,[3,5]);
vTest = reshape(vTest,[3,5]);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% triu
aTest = triu(aTest);
vTest = triu(vTest);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% repmat
aTest = repmat(aTest,2,3);
vTest = repmat(vTest,2,3);
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% mpower
% mpower is supported since casadi 3.3
aTest = aTest(:,1:6)^2;
vTest = vTest(:,1:6)^2;
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(all(all(vTest-full(f(v1,v2))< eps)))

%%% mldivide (solve in casadi)
A = [0.2625    0.9289    0.5785;
     0.8010    0.7303    0.2373;
     0.0292    0.4886    0.4588];
b = [0.9631,0.5468,0.5211]';

aA = ocl.casadi.CasadiVariable.Matrix([3,3],mx);
ab = ocl.casadi.CasadiVariable.Matrix([3,1],mx);

sA = aA.value;
sb = ab.value;

aTest = aA\ab;
vTest = A\b;
f = casadi.Function('f',{sA,sb},{aTest.value});
assert(all( abs(full(f(A,b))-vTest) <= eps))

%%% cross
aTest = cross(a1,a2(2,:).');
vTest = cross(v1,v2(2,:).');
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% dot
aTest = dot(a1,a2(2,:).');
vTest = dot(v1,v2(2,:).');
f = casadi.Function('f',{s1,s2},{aTest.value});
assert(isequal(full(f(v1,v2)),vTest))

%%% inv
aTest = inv(aA);
vTest = inv(A);
f = casadi.Function('f',{sA},{aTest.value});
assert( all(all( abs(full(f(A))-vTest) <= eps)))

%%% det
aTest = det(aA);
vTest = det(A);
f = casadi.Function('f',{sA},{aTest.value});
assert( abs(full(f(A))-vTest) <= eps)

%%% trace
aTest = trace(aA);
vTest = trace(A);
f = casadi.Function('f',{sA},{aTest.value});
assert(isequal(full(f(A)),vTest))

%%% diag
aTest = diag(aA);
vTest = diag(A);
f = casadi.Function('f',{sA},{aTest.value});
assert(isequal(full(f(A)),vTest))

%%% polyval
aTest = polyval([2;5;4],a1);
vTest = polyval([2;5;4],v1);
f = casadi.Function('f',{s1},{aTest.value});
assert(isequal(full(f(v1)),vTest))

ab.set([2,5,4].');
aTest = polyval(ab,a1);
vTest = polyval([2,5,4].',v1);
f = casadi.Function('f',{s1},{aTest.value});
assert(isequal(full(f(v1)),vTest))

%%% jacobian
% test against finite diff jacobian
aTest = jacobian(testJacobianFun(a1),a1);
vTest = finiteDiffJac(@testJacobianFun,v1);
f = casadi.Function('f',{s1},{aTest.value});
assert(all(all( abs(full(f(v1))-vTest) <= eps)))

%%% jtimes
aTest = jtimes(testJacobianFun(a1),a1,a1);
vTest = vTest * v1;
f = casadi.Function('f',{s1},{aTest.value});
assert(all(all( abs(full(f(v1))-vTest) <= 10*eps)))

%%% plus,minus,times,power,rdivide
aTest = a1(1).^2*a1(2)+a1(3)-a1(2)./a1(3).\a1(1);
vTest = v1(1).^2*v1(2)+v1(3)-v1(2)./v1(3).\v1(1);
f = casadi.Function('f',{s1},{aTest.value});
assert(isequal(full(f(v1)),vTest))

%%% abs,sqrt,sin,cos,tan,atan,asin,acos,atanh,asinh,acosh,exp,log,tanh,cosh,sinh
aTest = tanh(acosh(atan(a1(1)).^2));
aTest = sinh(aTest * sqrt(a1(2))+asinh(abs(a1(3))-log(sin(a1(2)))));
aTest = cosh(acos(asin(aTest * exp(atanh(cos(a1(3)))).\tan(a1(1))+1)));

vTest = tanh(acosh(atan(v1(1)).^2));
vTest = sinh(vTest * sqrt(v1(2))+asinh(abs(v1(3))-log(sin(v1(2)))));
vTest = cosh(acos(asin(vTest * exp(atanh(cos(v1(3)))).\tan(v1(1))+1)));

f = casadi.Function('f',{s1},{aTest.value});
assert(abs(full(f(v1)) - vTest) < eps)

%%% atan2, times
aTest = atan2(a1(1).^2.*a1(2)+a1(3),atan(a1(1)).^2);
vTest = atan2(v1(1).^2.*v1(2)+v1(3),atan(v1(1)).^2);
f = casadi.Function('f',{s1},{aTest.value});
assert(isequal(full(f(v1)),vTest))

%%% (:)
%aTest = [a1,a1,a1;a2];
%vTest = [v1,v1,v1;v2];
%aTest(:) = 2;
%vTest(:) = 2;
%f = casadi.Function('f',{s1,s2},{aTest.value});
%assert(isequal(full(f(v1,v2)),vTest))

% keep type
assert(isa(aTest,'ocl.casadi.CasadiVariable'));

end

function v = testJacobianFun(x)
  v = x*x(1)+cross([x(1);x(3)^2;x(2)],x);
end

function J = finiteDiffJac(functionHandle,x)
  FDeps = 1e-6;
  fx = functionHandle(x);
  Ncols = numel(x);
  Nrows = numel(fx);
  J = zeros(Nrows,Ncols);
  for k=1:Ncols
    dx = zeros(Ncols,1);
    dx(k) = FDeps;
    J(:,k) = (functionHandle(x+dx) - fx) / FDeps;
  end
end

