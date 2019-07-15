function r = normalizedStateTimes(H_norm)
r = [0, cumsum(H_norm)]';