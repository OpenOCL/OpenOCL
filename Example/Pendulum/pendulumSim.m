StartupOC

% Create system and OCP
parameters = Parameters;
parameters.add('m',[1 1]);
parameters.add('l',[1 1]);

system = PendulumSystem(parameters);
simulator = Simulator(system,struct);

states = simulator.getStates;
states.get('p').set([0,1]);
states.get('v').set([0.5,1]);
times = 0:0.1:10;

p = Arithmetic(parameters,0);
p.get('m').set(1);
p.get('l').set(1);

% simulate using feedback control (implemented in simulationCallback)
figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(states,times,p);


% simulate again using a given series of control inputs
controlsSeries = simulator.getControlsSeries(length(times)-1);
controlsSeries.get('controls').get('F').set(1);

figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(states,times,controlsSeries,p);