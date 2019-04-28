function fig = oclFigure

  fig = figure;
  set(fig,'Color','white')
  fig.OuterPosition = fig.InnerPosition;
  
  daspect([1 1 1])
  pbaspect([16 9 1])

end