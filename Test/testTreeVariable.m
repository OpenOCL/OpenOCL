function testTreeVariable
  
xStruct = TreeNode('x');
xStruct.add('x1',[1,2]);
xStruct.add('x2',[3,2]);
xStruct.add('x1',[1,2]);

x = Variable(xStruct,4);

%%% set
x.set(1:10);
assert(isequal(x.value,(1:10)'))

%%% get by id
assert(isequal(x.get('x1').value,[1,9;2,10]));
assert(isequal(x.x1.value,[1,9;2,10]));

%%% get by selector
x1 = x.get('x1');
assert(isequal(x1.get(2).value,[9,10]));
assert(isequal(x.x1(2).value,[9,10]));

%%% get by selector and set
x1.get(2).set([4,5])
assert(isequal(x1.get(2).value,[4,5]));

x = TreeNode('x');
x.add('p',[3,1]);
x.add('R',[3,3]);
x.add('v',[3,1]);
x.add('w',[3,1]);

u = TreeNode('u');
u.add('elev',[1,1]);
u.add('ail',[1,1]);

state = Variable(x,0);

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

ocpVar = TreeNode('ocpvar');
ocpVar.addRepeated({x,u},5);
ocpVar.add(x);

v = Variable(ocpVar,0);
state = v.get('x');
state.get('R').set(eye(3))
state.get('p').set([100;0;50])
state.get('v').set([20;0;0])
state.get('w').set([0;1;0.1])

assert( isequal( state.value,   [
  100.0000  100.0000  100.0000  100.0000  100.0000  100.0000
         0         0         0         0         0         0
   50.0000   50.0000   50.0000   50.0000   50.0000   50.0000
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
   20.0000   20.0000   20.0000   20.0000   20.0000   20.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
    0.1000    0.1000    0.1000    0.1000    0.1000    0.1000] ) );

assert( isequal( state.value,   [
  100.0000  100.0000  100.0000  100.0000  100.0000  100.0000
         0         0         0         0         0         0
   50.0000   50.0000   50.0000   50.0000   50.0000   50.0000
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
   20.0000   20.0000   20.0000   20.0000   20.0000   20.0000
         0         0         0         0         0         0
         0         0         0         0         0         0
         0         0         0         0         0         0
    1.0000    1.0000    1.0000    1.0000    1.0000    1.0000
    0.1000    0.1000    0.1000    0.1000    0.1000    0.1000] ) );

assert( isequal( v.get('x',4:6).get('p').value, ... 
                 [100   100   100
                   0     0     0
                  50    50    50]));
  
% this should not print warnings
v.get('x',4:6).get('p').set(eye(3));
assert( isequal(v.get('x',4:6).get('p').value, eye(3)) );

assert( isequal(v.get('x',4:6).get('p').size, [3 3]) );

v.get('x').get('R').set(eye(3));
assert( isequal(v.get('x').get('R').value, repmat([1,0,0,0,1,0,0,0,1]',1,6)) );

v.get('x').get('R').set(ones(9,1))
assert( isequal(v.get('x').get('R').value, ones(9,6)) );


%assert( isequal(v.get('x').get('R',1,1).value,ones(1,6)) );

% how about v.get(1,'x') to get the first x
% v.get('x').get(2,'R') to get the second R in x
% vs v.get('x').get('p',2) to get the second element of the ps: py
% could do v.get(1,'x').get('R',2)

p1 = v.get('x',1).get('p');
p2 = v.get('x',2).get('p');
p3 = p1 + p2;
p3 = p1 - p2;
p3 = p1 ./ p2;
p3 = p1'*p2;