% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function treeVariable

assertEqual = @ocl.utils.assertEqual;
assertSqueezeEqual = @ocl.utils.assertSqueezeEqual;

xStruct = ocl.types.Structure();
xStruct.add('x1',[1,2]);
xStruct.add('x2',[3,2]);
xStruct.add('x1',[1,2]);

x = ocl.Variable.create(xStruct,4);

%%% set
x(:) = (1:10).';
assertEqual(x.value,(1:10)');

%%% get by id
assertEqual(x.get('x1').value,[1,9;2,10]);
assertEqual(x.x1.value,[1,9;2,10]);

%%% slice
assertEqual(x.x1(1,:).value,[1,9]);

x = ocl.types.Structure();
x.add('p',[3,1]);
x.add('R',[3,3]);
x.add('v',[3,1]);
x.add('w',[3,1]);

u = ocl.types.Structure();
u.add('elev',[1,1]);
u.add('ail',[1,1]);

state = ocl.Variable.create(x,0);

state.R = eye(3);
state.p = [100;0;-50];
state.v = [20;0;0];
state.w = [0;1;0.1];

assertEqual( state.R.value,   eye(3) );
assertEqual( state.p.value,   [100;0;-50] );
assertEqual( state.v.value,   [20;0;0] );
assertEqual( state.w.value,   [0;1;0.1] );

state.p = [100;0;50];

assertEqual( state.get('p').value,   [100;0;50] );
assertEqual( state.size,   [18 1] );

ocpVar = ocl.types.Structure();
ocpVar.addRepeated({'x','u'},{x,u},5);
ocpVar.add('x',x);

v = ocl.Variable.create(ocpVar,0);
v.x.R.set(eye(3));
v.x.p.set([100;0;50]);
v.x.v.set([20;0;0]);
v.x.w.set([0;1;0.1]);

assertEqual( v.x.p(1,4:6).value, [100,100,100]);
assertEqual( v.x.R(1,4:6).value, [1,1,1]);
assertEqual( v.x.R(:,3).value, [1,0,0,0,1,0,0,0,1]');

v.get('x').get('R').set(eye(3));
assertEqual( v.x.get('R').value,   repmat(reshape(eye(3),9,1),1,6) );
assertEqual( v.x{1}.R.value, eye(3) );

v.get('x').get('R').set(ones(3,3));
assertEqual( v.x.R.value,   repmat(reshape(ones(3),9,1),1,6) );

% slice on selection
assertEqual( v.x{1}.p.value, [100;0;50] );

% :, end
assert(isequal(v(':').value,v.value))
v.x(:,:,end).set((2:19)');

assert(isequal(v.x(:,end).slice(2).value,3))

xend = v.x(:,end);
assert(isequal(xend(end).value,19))
assert(isequal(xend(2).value,3))
assert(isequal(xend(end).value,19))

% str
v.str();
v.x.str();
v.x.R.str();

% automatic slice testing
A = randi(10,v.x.R.size);
v.x.R.set(A);

assertEqual(v.x.R(1).value, A(1));
assertEqual(v.x.R(1,1).value, A(1,1));
assertEqual(v.x.R(3,1).value, A(3,1));
assertEqual(v.x.R(2,3).value, A(2,3));
assertEqual(v.x{1}.R(1,1).value, A(1,1,1));

Ap = reshape(A(:,4), 3, 3);
assertEqual(v.x{4}.R(2,3).value, Ap(2,3));

assertEqual(v.x.R(:).value, A(:));
assertEqual(v.x.R(:,:).value, A(:,:));

assertSqueezeEqual(v.x.R(:,:).value, A(:,:) );

assertEqual(v.x.R(end).value, A(end));
assertEqual(v.x.R(end,end).value, A(end,end));

assertEqual(v.x.R(end-3).value, A(end-3));
assertEqual(v.x.R(end-2,end-3).value, A(end-2,end-3));

assertEqual(v.x.R(:,2).value, A(:,2));

% set tests
% if ~ocl.utils.isOctave()
%   v.x.R{end} = eye(3);
%   assertEqual( v.x.R(:,end).value, [1,0,0,0,1,0,0,0,1]; );
% end


