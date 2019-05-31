% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function animateRaceCar(time,solution,x_road,y_center,y_min,y_max)

ts = time(2)-time(1);
x_car = solution.states.x.value;
y_car = solution.states.y.value;

%% Initialize animation
figure('units','normalized');hold on;grid on;
car = plot(x_car(1),y_car(1),'Marker','pentagram','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',15);
carLine = plot(x_car(1),y_car(1),'Color','b','LineWidth',3);
plot(x_road,y_center,'Color','k','LineWidth',1,'LineStyle','--');
plot(x_road,y_min   ,'Color','k','LineWidth',2.0,'LineStyle','-');
plot(x_road,y_max   ,'Color','k','LineWidth',2.0,'LineStyle','-');
legend('car','car trajectory');
axis equal;xlabel('x[m]');ylabel('y[m]');
pause(ts)
%%
for i = 2:1:length(time)
  set(carLine, 'XData' , x_car(1:i));
  set(carLine, 'YData' , y_car(1:i));
  set(car    , 'XData' , x_car(i));
  set(car    , 'YData' , y_car(i));
  
  global testRun
  if isempty(testRun) || (testRun==false)
    pause(ts);
  end

  drawnow
end