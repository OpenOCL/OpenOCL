% Create system and simulator
system = PendulumSystem;
options = Simulator.getOptions;
simulator = Simulator(system,options);

states = simulator.getStates;
states.get('p').set([0,1]);
states.get('v').set([0.5,1]);
times = 0:0.1:10;

p = simulator.getParameters;
p.get('m').set(1);
p.get('l').set(1);

% simulate using feedback control (implemented in simulationCallback)
figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(states,times,p);


% simulate again using a given series of control inputs
controlsSeries = simulator.getControlsSeries(length(times)-1);
controlsSeries.get('F').set(1);

figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(states,times,controlsSeries,p);