function varsfun(sh)
  sh.addState('p', 2);
  sh.addState('v', 2);

  sh.addParameter('T');
  
  sh.addControl('F');
  sh.addAlgVar('lambda');
end