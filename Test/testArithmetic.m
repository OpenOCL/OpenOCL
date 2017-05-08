function testArithmetic

% small number of numeric value comparison
eps = 1e-6;

sx1 = casadi.SX.sym('x1',3,1);
sx2 = casadi.SX.sym('x2',2,3);

vx1 = [5;3;2];
vx2 = [1,5,3;6,5,4];

%%% constructor
a1 = Arithmetic;
a2 = Arithmetic;
a1.setValue(sx1);
a2.setValue(sx2);
assert(isa(a1.value,'casadi.SX'));
f = casadi.Function('f',{sx1},{a1.value});
assert(isequal(full(f(vx1)),vx1))
f = casadi.Function('f',{sx2},{a2.value});
assert(isequal(full(f(vx2)),vx2))

%%% horzcat, vertcat, subsref
aTest = [a1,a1,a1;a2];
aTest = aTest(3:5,2);
vTest = [vx1,vx1,vx1;vx2];
vTest = vTest(3:5,2);
f = casadi.Function('f',{sx1,sx2},{aTest(1:2).value});
assert(isequal(full(f(vx1,vx2)),vTest(1:2)))

%%% subsasgn
aTest(2:3) = 11;
vTest(2:3) = 11;
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% norm
aTest = norm(aTest);
vTest = norm(vTest);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% sum
aTest = [a1,a1,a1;a2];
aTest = sum(aTest);
vTest = [vx1,vx1,vx1;vx2];
vTest = sum(vTest);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% mtimes
aTest = [a1,a1,a1;a2] * 4 * sx1 * [2,3,4];
vTest = [vx1,vx1,vx1;vx2] * 4 * vx1 * [2,3,4];
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% transpose
aTest = aTest';
vTest = vTest';
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))
aTest = aTest.';
vTest = vTest.';
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% reshape
aTest = reshape(aTest,15,1);
vTest = reshape(vTest,15,1);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))
aTest = reshape(aTest,[3,5]);
vTest = reshape(vTest,[3,5]);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% triu
aTest = triu(aTest);
vTest = triu(vTest);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% repmat
aTest = repmat(aTest,2,3);
vTest = repmat(vTest,2,3);
f = casadi.Function('f',{sx1,sx2},{aTest.value});
assert(isequal(full(f(vx1,vx2)),vTest))

%%% mpower
% Matrix power is not support by the time of writing so it should raise an
% error. This test should adapted once casadi support matrix power.
errorThrown = false;
try
  [~] = aTest(:,1:6)^2;
catch
  errorThrown = true;
end
assert(errorThrown)

%%% mldivide (solve in casadi)
A = [0.2625    0.9289    0.5785;
     0.8010    0.7303    0.2373;
     0.0292    0.4886    0.4588];
b = [0.9631,0.5468,0.5211]';

sxSquare = casadi.SX.sym('xSquare',3,3);

aA = Arithmetic(sxSquare);
ab = Arithmetic(sx1);

aTest = aA\ab;
vTest = A\b;
f = casadi.Function('f',{sxSquare,sx1},{aTest.value});
assert(all(full(f(A,b))-vTest <= eps))

