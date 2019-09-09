% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function structure

assertEqual = @ocl.utils.assertEqual;
 
x = ocl.types.Structure();
assertEqual(x.size,[0 1]);
x.add('x1',[1,2]);
x.add('x2',[3,2]);

[~,p]=x.get('x1',(1:prod(x.size))');
assertEqual(p,[1;2])
[~,p]=x.get('x2',(1:prod(x.size))');
assertEqual(p,[3,4,5,6,7,8]')
assertEqual(x.size,[8 1])

x = ocl.types.Structure();
x.add('x1',[1,8]);
assertEqual(x.size,[8 1])

x = ocl.types.Structure();
x.add('x1',[1,3]);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

[~,p] = x.get('x1');
assertEqual(p,[1,2,3;10,11,12]')
[~,p] = x.get('x2');
assertEqual(p,(4:9)')

u = ocl.types.Structure();
u.add('x1',[1,3]);
u.add('x3',[3,3]);
u.add('x1',[1,3]);
u.add('x3',[3,3]);

x = ocl.types.Structure();
x.add('x1',[1,3]);
x.add('u',u);
x.add('u',u);
x.add('x2',[3,2]);
x.add('x1',[1,3]);

y = ocl.types.Structure();
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);
y.add('x1',[1,2]);

% get by name
[t,p] = x.get('u');
[~,p] = t.get('x1',p);
assertEqual(p, [4,5,6;16,17,18;28,29,30;40,41,42]');

% get by selector
[t,p] = x.get('u');
p = p(:,1);
[~,p] = t.get('x1',p);
assertEqual(p, [4,5,6;16,17,18]');




