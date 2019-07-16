function guess = igFromBounds(lower, upper)
% Averages the bounds to get an initial guess value.
% Makes sure no nan values are produced, defaults to 0.

guess = (lower + upper) / 2;

% set to lowerBounds if upperBounds are inf
indizes = isinf(upper);
guess(indizes) = lower(indizes);

% set to upperBounds of lowerBoudns are inf
indizes = isinf(lower);
guess(indizes) = upper(indizes);

% set to zero if both lower and upper bounds are inf
indizes = isinf(lower) & isinf(upper);
guess(indizes) = 0;