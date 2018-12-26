function r = isOctave()
  r = exist('OCTAVE_VERSION', 'builtin') > 0;
end
