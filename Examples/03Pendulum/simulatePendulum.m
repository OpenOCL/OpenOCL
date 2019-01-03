% Create system and simulator
system = PendulumSystem;
simulator = Simulator(system);

states = simulator.getStates();
states.p.set([0,1]);
states.v.set([-0.5,-1]);

p = simulator.getParameters();
p.m.set(1);
p.l.set(1);

times = 0:0.1:4;

% simulate without control inputs
simulator.simulate(states,times,p);

% simulate again using a given series of control inputs
controlsSeries = simulator.getControlsVec(length(times)-1);
controlsSeries.F.set(10);

[statesVec,algVarsVec,controlsVec] = simulator.simulate(states,times,controlsSeries,p);