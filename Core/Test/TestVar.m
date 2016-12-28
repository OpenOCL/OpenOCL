% clear classes
state = Var('x');
state.add('p',[3,1]);
state.add('R',[3,3]);
state.add('v',[3,1]);
state.add('w',[3,1]);
state.compile;

state.get('R').set(eye(3))
state.get('p').set([100;0;-50])
state.get('v').set([20;0;0])
state.get('w').set([0;1;0.1])

assert( isequal( state.get('R').value,   eye(3) ) )
assert( isequal( state.get('p').value,   [100;0;-50] ) )
assert( isequal( state.get('v').value,   [20;0;0] ) )
assert( isequal( state.get('w').value,   [0;1;0.1] ) )

state2 = state.copy;
state2.get('p').set([1;2;3])
state.get('p').set([100;0;50])

assert( isequal( state.get('p').value,   [100;0;50] ) )
assert( isequal( state2.get('p').value,   [1;2;3] ) )

assert( isequal( state.size,   [18 1] ) )



control = Var('u');
control.add('elev',[1,1]);
control.add('ail',[1,1]);
control.compile;

ocpVar = Var('ocpvar');
ocpVar.addRepeated([state,control],5);
ocpVar.add(state);

assert( isequal( ocpVar.get('x').value,   [
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

ocpVar.compile

assert( isequal( ocpVar.get('x').value,   [
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



  
  
assert( isequal( ocpVar.get('x',4:6).get('p').value, ... 
                 [100   100   100
                   0     0     0
                  50    50    50]));
  

printString = evalc('ocpVar.get(''x'',1:2).printStructure');
indizes = regexp(printString,'x1|x2|v|p');
assert(isequal(indizes, [6,17,20,30,43,46,56,65,76,79,89,102,105,115]));

