function animateRaceCar(time,solution,x_road,y_center,y_min,y_max)

ts = time(2)-time(1);
x_car = solution.get('states').get('x').value;
y_car = solution.get('states').get('y').value;

%% Initialize animation
figure('units','normalized','outerposition',[0 0 1 1]);hold on;grid on;
car = plot(x_car(1),y_car(1),'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',10);
carLine = plot(x_car(1),y_car(1),'Color','b','LineWidth',1.5);
plot(x_road,y_center,'Color','k','LineWidth',0.5,'LineStyle','--');
plot(x_road,y_min   ,'Color','k','LineWidth',1.0,'LineStyle','-');
plot(x_road,y_max   ,'Color','k','LineWidth',1.0,'LineStyle','-');
legend('car','car trajectory');
axis equal;xlabel('x[m]');ylabel('y[m]');
pause(ts)
%%
for i = 2:1:length(time)
  set(carLine, 'XData' , x_car(1:i));
  set(carLine, 'YData' , y_car(1:i));
  set(car    , 'XData' , x_car(i));
  set(car    , 'YData' , y_car(i));
  pause(ts)
  drawnow
end