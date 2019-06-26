function guess = igFromBounds(bounds)
% Averages the bounds to get an initial guess value.
% Makes sure no nan values are produced, defaults to 0.

lowVal  = bounds.lower;
upVal   = bounds.upper;

guess = (lowVal + upVal) / 2;

% set to lowerBounds if upperBounds are inf
indizes = isinf(upVal);
guess(indizes) = lowVal(indizes);

% set to upperBounds of lowerBoudns are inf
indizes = isinf(lowVal);
guess(indizes) = upVal(indizes);

% set to zero if both lower and upper bounds are inf
indizes = isinf(lowVal) & isinf(upVal);
guess(indizes) = 0;