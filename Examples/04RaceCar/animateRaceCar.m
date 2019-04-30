function animateRaceCar(time,solution,x_road,y_center,y_min,y_max, recordVideo)

if nargin < 7
  recordVideo = false;
end

if recordVideo
  assert(all(time)==time(1));
  v = VideoWriter(['Workspace/racecar_', datestr(now,'yyyy-mm-dd_HHMMSS')]);
  v.FrameRate = floor(1./(time(2)-time(1)));
  open(v);
end

ts = time(2)-time(1);
x_car = solution.states.x.value;
y_car = solution.states.y.value;

% Initialize animation
fig = figure('units','normalized');
set(fig,'Color','white')
fig.OuterPosition = fig.InnerPosition;
xticks(-5:5)
yticks(-5:5)
pbaspect([16 9 1])
daspect([1 1 1])
hold on;grid on;
car = plot(x_car(1),y_car(1),'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',20);
carLine = plot(x_car(1),y_car(1),'Color','b','LineWidth',3);
plot(x_road,y_center,'Color','k','LineWidth',1,'LineStyle','--');
plot(x_road,y_min   ,'Color','k','LineWidth',2.0,'LineStyle','-');
plot(x_road,y_max   ,'Color','k','LineWidth',2.0,'LineStyle','-');
legend('car','car trajectory');
axis equal;xlabel('x[m]');ylabel('y[m]');
pause(ts)
%
for i = 2:1:length(time)
  set(carLine, 'XData' , x_car(1:i));
  set(carLine, 'YData' , y_car(1:i));
  set(car    , 'XData' , x_car(i));
  set(car    , 'YData' , y_car(i));
  drawnow 
  
  if recordVideo
    frame = getframe(fig);
    writeVideo(v, frame);
  end
  
  global testRun
  if isempty(testRun) || (testRun==false)
    pause(ts);
  end
  
end