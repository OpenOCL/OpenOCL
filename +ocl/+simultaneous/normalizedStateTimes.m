function r = normalizedStateTimes(stage)
r = [0, cumsum(stage.H_norm)]';