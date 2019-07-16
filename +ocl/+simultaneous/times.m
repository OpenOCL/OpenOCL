function stage_time_struct = times(stage,colloc)
stage_time_struct = OclStructure();
stage_time_struct.addRepeated({'states', 'integrator', 'controls'}, ...
  {OclMatrix([1,1]), OclMatrix([colloc.num_t,1]), OclMatrix([1,1])}, length(stage.H_norm));
stage_time_struct.add('states', OclMatrix([1,1]));
