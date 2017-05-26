function testVarStructure


x = TreeNode('x');

assert(isequal(x.size,[0 1]));

x.add('x1',[1,2]);
x.add('x2',[3,2]);

assert(isequal(x.get('x1').positions,{[1,2]}))
assert(isequal(x.get('x2').positions,{[3:8]}))
assert(isequal(x.size,[8 1]));

x = TreeNode('x',[3,1]);
assert(isequal(x.size,[3 1]));

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



assert( isequal( x.get('u').get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

uhat = x.get('u');
assert( isequal( uhat.get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

% positions
x = TreeNode('x',[3 3]);
y = TreeNode('y',[1 1]);
z = TreeNode('z',[4 5]);
v = TreeNode('v');
v.add(x);
v.add(y);
v.add(z);
v.add(x);

vars = Arithmetic(v,0);
vars.get('z').value
vars.get('x').value

vars.get('x').set(rand(3));


