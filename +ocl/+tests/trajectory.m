assertEqual = @ocl.utils.assertEqual;

x_struct = ocl.types.Structure;
x_struct.add('p',[3,1]);
x_struct.add('w',[1,1]);
x_struct.add('R',[3,3]);

t = linspace(0,10,51);
p = [sin(t);cos(t);2*sin(t)];
w = tanh(t);
R = [t;t;t;2*t;2*t;2*t;3*t;3*t;3*t];
x_data = [p;w;R];

x_traj = ocl.types.Trajectory(x_struct, t, x_data);

assertEqual(x_traj.gridpoints, t);

assertEqual(x_traj{21}.get('p').value, p(:,21));
assertEqual(x_traj.at(t(21)).get('p').value, p(:,21));

assertEqual(x_traj{12:15}.get('p').value, p(:,12:15));

assertEqual(x_traj.at(t(21)).p.value, p(:,21));