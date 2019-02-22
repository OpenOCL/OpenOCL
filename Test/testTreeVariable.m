function testTreeVariable

xStruct = OclTreeBuilder();
xStruct.add('x1',[1,2]);
xStruct.add('x2',[3,2]);
xStruct.add('x1',[1,2]);

x = OclTensor.create(xStruct,4);

%%% set
x(:) = (1:10).';
assert(isequal(x.value,(1:10)'))

%%% get by id
assertSqueezeEqual(x.get('x1').value,[1,9;2,10]);
assertSqueezeEqual(x.x1.value,[1,9;2,10]);

%%% slice
assertSqueezeEqual(x.x1(1,1,:).value,[1;9]);

x = OclTreeBuilder();
x.add('p',[3,1]);
x.add('R',[3,3]);
x.add('v',[3,1]);
x.add('w',[3,1]);

u = OclTreeBuilder();
u.add('elev',[1,1]);
u.add('ail',[1,1]);

state = OclTensor.create(x,0);

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
assertSqueezeEqual( state.size,   [18 1] );

ocpVar = OclTreeBuilder();
ocpVar.addRepeated({'x','u'},{x,u},5);
ocpVar.add('x',x);

v = OclTensor.create(ocpVar,0);
v.x.R.set(eye(3));
v.x.p.set([100;0;50]);
v.x.v.set([20;0;0]);
v.x.w.set([0;1;0.1]);

assertSqueezeEqual( v.x.p(1,:,4:6).value, [100;100;100]);


v.get('x').get('R').set(eye(3));
assertEqual(v.x.get('R').value,   shiftdim(num2cell(repmat(eye(3),1,1,6), 1:2), 1)    );
assertEqual(v.x.R(:,:,1).value,eye(3));

v.get('x').get('R').set(ones(3,3));
assertEqual(v.x.R.value,   shiftdim(num2cell(repmat(ones(3),1,1,6), 1:2), 1));

% slice on selection
assertEqual(v.x.p(:,:,1).value,[100;0;50]);

% :, end
assertEqual(v(':').value,v.value);
v.x(:,end).set((2:19)');

assertEqual(v.x(:,end).slice(2).value,3);

xend = v.x(:,end);
assertEqual(xend(end).value,19);
assertEqual(xend(2).value,3);
assertEqual(xend(end).value,19);

% str
v.str();
v.x.str();
v.x.R.str();

% automatic slice testing
A = randi(10,v.x.R.size);
v.x.R.set(num2cell(A,[1,2]));

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

% set tests
if ~isOctave()
  v.x.R(:,:,end) = eye(3);
  assertEqual( v.x.R(:,:,end).value, eye(3) );
end


