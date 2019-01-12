function testTreeVariable

xStruct = OclStructure();
xStruct.add('x1',[1,2]);
xStruct.add('x2',[3,2]);
xStruct.add('x1',[1,2]);

x = Variable.create(xStruct,4);

%%% set
x.set((1:10).');
assert(isequal(x.value,(1:10)'))

%%% get by id
assert(isequal(x.get('x1').value,[1,9;2,10]));
assert(isequal(x.x1.value,[1,9;2,10]));

%%% slice
assert(isequal(x.x1(1,1,:).value,[1;9]));

x = OclStructure();
x.add('p',[3,1]);
x.add('R',[3,3]);
x.add('v',[3,1]);
x.add('w',[3,1]);

u = OclStructure();
u.add('elev',[1,1]);
u.add('ail',[1,1]);

state = Variable.create(x,0);

state.R = eye(3);
state.p = [100;0;-50];
state.v = [20;0;0];
state.w = [0;1;0.1];

assert( isequal( state.R.value,   eye(3) ) )
assert( isequal( state.p.value,   [100;0;-50] ) )
assert( isequal( state.v.value,   [20;0;0] ) )
assert( isequal( state.w.value,   [0;1;0.1] ) )

state.p = [100;0;50];

assert( isequal( state.get('p').value,   [100;0;50] ) )
assert( isequal( state.size,   [18 1] ) )

ocpVar = OclStructure();
ocpVar.addRepeated({'x','u'},{x,u},5);
ocpVar.add('x',x);

v = Variable.create(ocpVar,0);
v.get('x').R = eye(3);
v.get('x').get('p') = [100;0;50];
v.get('x').get('v') = [20;0;0];
v.get('x').w = [0;1;0.1];

assert( isequal( v.x(:,:,4:6).p(1,:,:).value, [100;100;100]));


v.get('x').R = eye(3);
assert( isequal(v.x.get('R').value,   shiftdim(num2cell(repmat(eye(3),1,1,6), 1:2), 1)    ));
assert(isequal(v.x(:,:,1).R.value,eye(3)))

v.get('x').get('R') = ones(3,3);
assert( isequal(v.x.R.value,   shiftdim(num2cell(repmat(ones(3),1,1,6), 1:2), 1)    ));

% slice on selection
assert(isequal(v.x(:,:,1).p.value,[100;0;50]))

% :, end
assert(isequal(v(':').value,v.value))
v.x(:,:,end) = (2:19)';

assert(isequal(v.x(:,:,end).get(2).value,3))

xend = v.x(:,:,end);
assert(isequal(xend(end).value,19))
assert(isequal(xend(2).value,3))
assert(isequal(xend(end).value,19))

% str
v.str();
v.x.str();
v.x.R.str();

% automatic slice testing
A = randi(10,v.x.R.size);
v.x.R = num2cell(A,[1,2]);

assertEqual(v.x.R(1).value, A(1));
assertEqual(v.x.R(1,1).value, A(1,1));
assertEqual(v.x.R(3,1).value, A(3,1));
assertEqual(v.x.R(2,3).value, A(2,3));
assertEqual(v.x.R(1,1,1).value, A(1,1,1));
assertEqual(v.x.R(2,3,4).value, A(2,3,4));

assertEqual(v.x.R(:).value, A(:));
assertEqual(v.x.R(:,:).value, A(:,:));


assertSqueezeEqual(v.x.R(:,:,:).value, A(:,:,:) );

assertEqual(v.x.R(end).value, A(end));
assertEqual(v.x.R(end,end).value, A(end,end));
assertEqual(v.x.R(end,end,end).value, A(end,end,end));

assertEqual(v.x.R(end-3).value, A(end-3));
assertEqual(v.x.R(end-2,end-3).value, A(end-2,end-3));
assertEqual(v.x.R(end,:,end-4).value, A(end,:,end-4));

assertSqueezeEqual(v.x.R(1:2,[1,3],2:5).value, A(1:2,[1,3],2:5));
assertSqueezeEqual(v.x.R(:,2,:).value, A(:,2,:));
assertEqual(v.x.R(:,:,3).value, A(:,:,3));
assertEqual(v.x.R(:,2).value, A(:,2));

