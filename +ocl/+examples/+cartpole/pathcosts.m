function pathcosts(ch, x, z, u, p)

ch.add( 1e3  * x.p^2     );
ch.add( 1e-2 * x.v^2     );
ch.add( 1e3  * x.theta^2 );
ch.add( 1e-2 * x.omega^2 );

ch.add( 1e-2 * u.F^2     );
