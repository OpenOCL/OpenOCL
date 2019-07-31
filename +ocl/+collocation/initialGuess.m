function r = initialGuess(i_vars, stateGuess, algvarGuess)
ig = ocl.Variable.create(i_vars, 0);
ig.states.set(stateGuess);
ig.algvars.set(algvarGuess);
r = ig.value;