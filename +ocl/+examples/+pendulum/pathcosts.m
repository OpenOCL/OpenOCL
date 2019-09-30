function pathcosts(ch,~,~,controls,~)
F  = controls.F;
ch.add( 1e-3*F^2 );
