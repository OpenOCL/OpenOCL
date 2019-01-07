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

state.get('R').set(eye(3))
state.get('p').set([100;0;-50])
state.get('v').set([20;0;0])
state.get('w').set([0;1;0.1])

assert( isequal( state.get('R').value,   eye(3) ) )
assert( isequal( state.get('p').value,   [100;0;-50] ) )
assert( isequal( state.get('v').value,   [20;0;0] ) )
assert( isequal( state.get('w').value,   [0;1;0.1] ) )

state.get('p').set([100;0;50])

assert( isequal( state.get('p').value,   [100;0;50] ) )
assert( isequal( state.size,   [18 1] ) )

ocpVar = OclStructure();
ocpVar.addRepeated({'x','u'},{x,u},5);
ocpVar.add('x',x);

v = Variable.create(ocpVar,0);
v.get('x').get('R').set(eye(3))
v.get('x').get('p').set([100;0;50])
v.get('x').get('v').set([20;0;0])
v.get('x').get('w').set([0;1;0.1])

assert( isequal( v.x(:,:,4:6).p(1,:,:).value, [100;100;100]));
  

v.get('x').get('R').set(eye(3));
assert( isequal(v.get('x').get('R').value,   shiftdim(num2cell(repmat(eye(3),1,1,6), 1:2), 1)    ));
assert(isequal(v.x(:,:,1).R.value,eye(3)))

v.get('x').get('R').set(ones(3,3))
assert( isequal(v.x.R.value,   shiftdim(num2cell(repmat(ones(3),1,1,6), 1:2), 1)    ));

% slice on selection
assert(isequal(v.x(:,:,1).p.value,[100;0;50]))

% :, all, end
assert(isequal(v('all').value,v.value)) 
if ~isOctave
  assert(isequal(v(':').value,v.value))
end
v.x(:,:,'end').set((2:19)')

assert(isequal(v.x(:,:,'end').get(2).value,3))

assert(isequal(v.x(:,:,'end').get('end').value,19))
assert(isequal(v.x(:,:,'end').get(2).value,3))
assert(isequal(v.x(:,:,'end').get('end').value,19))

% str
v.str();
v.x.str();
v.x.R.str();

