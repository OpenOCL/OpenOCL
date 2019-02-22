function tree = oclFlattenTree(branch)
  tree = OclTreeBuilder();
  iterateLeafs(branch, tree);
end

function iterateLeafs(branch,treeOut)
  branchIds = fieldnames(branch.branches);
  for k=1:length(branchIds)
    id = branchIds{k};
    childBranch = branch.get(id);
    if childBranch.hasBranches
      iterateLeafs(childBranch,treeOut);
    else
      treeOut.addBranch(id, childBranch);
    end
  end
end 