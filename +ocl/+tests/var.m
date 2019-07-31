xs = ocl.types.Struct();
xs.add('p', [2,1]);
xs.add('R', [2,2], {'r11', 'r12', 'r21', 'r22'});

x = ocl.Var(xs, [4,5,1,0,0,1]);

ocl.utils.assertEqual(x.slice(1).value, 4);
ocl.utils.assertEqual(x.slice(3).value, 1);
ocl.utils.assertEqual(x.slice(5).value, 0);

ocl.utils.assertEqual(x.get('p').value, [4,5]);
ocl.utils.assertEqual(x.R.value, [1,0;0,1]);

ocl.utils.assertEqual(x.p(1).value, 4);
ocl.utils.assertEqual(x.p(2).value, 5);

ocl.utils.assertEqual(x.p(1,1).value, 4);
ocl.utils.assertEqual(x.p(2,1).value, 5);

ocl.utils.assertEqual(x.R(1).value, 1);
ocl.utils.assertEqual(x.R(2).value, 0);

ocl.utils.assertEqual(x.R(1,1).value, 1);
ocl.utils.assertEqual(x.R(2,2).value, 1);

% trajectory
xt = ocl.Trajectory(xs, 11);
xt.set([4,5,1,0,0,1]);

ocl.utils.assertEqual(xt{1}.value(), [4,5,1,0,0,1]');

