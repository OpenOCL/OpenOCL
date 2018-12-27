function testVarStructure
  
x = TreeNode('x');
assert(isequal(x.size,[0 1]));

x.add('x1',[1,2]);
x.add('x2',[3,2]);

assert(isequal(x.get('x1').positions,{[1,2]}))
assert(isequal(x.get('x2').positions,{[3:8]}))
assert(isequal(x.size,[8 1]));

x = TreeNode('x');
x.add('x1',[8,1]);

assert(isequal(x.size,[8 1]));

x = TreeNode('x');
x.add('x1',[1,3]);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

assert(isequal(x.get('x1').positions,{[1,2,3],[10,11,12]}))
assert(isequal(x.get('x2').positions,{[4:9]}))

u = TreeNode('u');
u.add('x1',[1,3]);
u.add('x3',[3,3]);
u.add('x1',[1,3]);
u.add('x3',[3,3]);

x = TreeNode('x');
x.add('x1',[1,3]);
x.add(u);
x.add(u);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

y = TreeNode('y');
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);

% get by name
assert( isequal( x.get('u').get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

% get by name in two steps
uhat = x.get('u');
assert( isequal( uhat.get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

% get by selector
assert( isequal( uhat.get(1).get('x1').positions, {[4,5,6],[16,17,18]} ));

% flat operator
t = x.getFlat();
assert(isequal ( t.get('x1').positions,{[1,2,3],[4,5,6],[16,17,18],[28,29,30],[40,41,42],[58,59,60]} ));

% slice TreeNoe, MatrixStructure, NodeSelection
assert(isequal(x.get('x1',1).positions,{[1],[58]}))
assert(isequal(x.get('x1',2).positions,{[2],[59]}))
assert(strcmp(class(x.get('x1',1:2).get(1)), 'MatrixStructure'))
assert(isequal(x.get('u',1).get('x1').positions,{[4,5,6],[16,17,18]}))
assert(isequal(x.get('u',1).get('x1',1).positions,{[4],[16]}))
assert(isequal(x.get('u',1).get('x1',1:2).positions,{[4,5],[16,17]}))
assert(isequal(x.get('u').get(2).get('x3').get(2).positions,{43:51}))
assert(strcmp(class(x.get('u',1).get('x1',1)), 'NodeSelection'))
assert(strcmp(class(x.get('u',1).get('x1',1).get(1)), 'MatrixStructure'))
assert(isequal(x.get('u',1).get('x1',1).get(1).positions,{[4]}))
assert(isequal(x.get('u',1).get('x3',[2,3;1,2]).get(2).positions,{[20,21;19,20]}))





