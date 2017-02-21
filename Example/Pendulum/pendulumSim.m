StartupOC

% Create system and OCP
parameters = Parameters;
parameters.add('m',[1 1]);
parameters.add('l',[1 1]);

system = PendulumSystem(parameters);
simulator = Simulator(system,struct);

state = simulator.getState;
state.get('p').set([0,1]);
state.get('v').set([0.5,1]);
times = 0:0.1:10;
parameters.get('m').set(1);
parameters.get('l').set(1);

% simulate using feedback control (implemented in simulationCallback)
figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(state,times,parameters);


% simulate again using a given series of control inputs
controlsSeries = simulator.getControlsSeries(length(times)-1);
controlsSeries.get('F').set(1);

figure;
[statesVec,algVarsVec,controlsVec] = simulator.simulate(state,times,controlsSeries,parameters);