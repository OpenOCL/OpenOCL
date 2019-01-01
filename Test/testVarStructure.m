function testVarStructure

  
a = OclMatrix([2,2]);
assertEqual(a.size(),[2 2]);
  
x = OclTree();
assertEqual(x.size,[0 1]);
x.add('x1',[1,2]);
x.add('x2',[3,2]);

[~,p]=x.get(1:prod(x.size),'x1');
assertEqual(p,[1,2])
[~,p]=x.get(1:prod(x.size),'x2');
assertEqual(p,[3,4,5;6,7,8]')
assertEqual(x.size,[8 1])

x = OclTree();
x.add('x1',[1,8]);
assertEqual(x.size,[8 1])

x = OclTree();
x.add('x1',[1,3]);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

[~,p] = x.get(1:prod(x.size),'x1');
assertSqueezeEqual(p,{[1,2,3],[10,11,12]})
[~,p] = x.get(1:prod(x.size),'x2');
assertSqueezeEqual(p,{4:9})

u = OclTree();
u.add('x1',[1,3]);
u.add('x3',[3,3]);
u.add('x1',[1,3]);
u.add('x3',[3,3]);

x = OclTree();
x.add('x1',[1,3]);
x.add('u',u);
x.add('u',u);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

y = OclTree();
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);

% get by name
[t,p] = x.get(1:prod(x.size),'u');
[~,p] = t.get(p,'x1');
assertSqueezeEqual(p, {[4,5,6],[16,17,18],[28,29,30],[40,41,42]} );

% get by selector
[t,p] = x.get(1:prod(x.size),'u');
[t,p] = t.get(p,1);
[~,p] = t.get(p,'x1');
assertSqueezeEqual(p, {[4,5,6],[16,17,18]} );

% flat operator
f = x.getFlat();
[t,p] = f.get(1:f.len,'x1');
assertSqueezeEqual(p,{[1,2,3],[4,5,6],[16,17,18],[28,29,30],[40,41,42],[58,59,60]} );



