function stage_time_struct = timesStruct(N, nt)
stage_time_struct = ocl.types.Structure();
stage_time_struct.addRepeated({'states', 'integrator', 'controls'}, ...
  {ocl.types.Matrix([1,1]), ocl.types.Matrix([nt,1]), ocl.types.Matrix([1,1])}, N);
stage_time_struct.add('states', ocl.types.Matrix([1,1]));