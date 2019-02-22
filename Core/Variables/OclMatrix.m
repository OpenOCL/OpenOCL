classdef OclMatrix < OclRootNode
  methods
    function self = OclMatrix(shape)
      self@OclRootNode(struct,shape,{1:prod(shape)});
    end
  end
end