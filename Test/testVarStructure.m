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

%%% get by name
assert( isequal( x.get('u').get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

%%% get by name in two steps
uhat = x.get('u');
assert( isequal( uhat.get('x1').positions, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} ));

%%% get by selector
assert( isequal( uhat.get(1).get('x1').positions, {[4,5,6],[16,17,18]} ));

%%% flat operator
t = x.getFlat();
assert(isequal ( t.get('x1').positions,{[1,2,3],[4,5,6],[16,17,18],[28,29,30],[40,41,42],[58,59,60]} ));

