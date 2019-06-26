function stage_time_struct = times(stage)
stage_time_struct = OclStructure();
stage_time_struct.addRepeated({'states', 'integrator', 'controls'}, ...
  {OclMatrix([1,1]), OclMatrix([stage.integrator.nt,1]), OclMatrix([1,1])}, length(stage.H_norm));
stage_time_struct.add('states', OclMatrix([1,1]));
