function report = getReportOctave(ME, TYPE, varargin)
  % Copyright (C) 2016 Andrew Thornton
  % Author: Andrew Thornton <art27@cantab.net>
  % Created: December 2015
  %
  % This function is part of Octave.
  %
  % Octave is free software; you can redistribute it and/or modify it
  % under the terms of the GNU General Public License as published by
  % the Free Software Foundation; either version 3 of the License, or (at
  % your option) any later version.
    if ~exist('TYPE', 'var')
        TYPE = 'extended';
    end
    if strcmpi(TYPE, 'basic')
        report = [ME.message];
    elseif (length(ME.stack) == 1)
        report = strvcat( ['Error using ' ME.stack(1).name ' (line ' num2str(ME.stack(1).line) ')'], ...
            [ME.message]);
    else
        msg = @(x) {['Error in ' x.name ' (line ' num2str(x.line) ')']};
        tmp = arrayfun(msg, ME.stack);
        report = strvcat(...
            ME.message, ...
            tmp{:});
    end
end



