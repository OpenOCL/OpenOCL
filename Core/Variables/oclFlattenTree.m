function tree = oclFlattenTree(rn)
  tree = OclTreeBuilder();
  iterateLeafs(rn, tree);
end

function iterateLeafs(node,treeOut)
  branchIds = fieldnames(node.branches);
  for k=1:length(branchIds)
    branch = branchIds{k};
    childNode = node.get(branch);
    if childNode.hasBranches
      iterateLeafs(childNode,treeOut);
    elseif numel(childNode) > 0
      treeOut.addNode(branch, childNode);
    end
  end
end 