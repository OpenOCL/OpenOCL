function animateBallAndBeam(time,rTrajectory,thetaTrajectory)

ts = time(2)-time(1);
L      = 1; % length beam [m]

%% Initialize animation
xbeam = L*cos(thetaTrajectory(1));
ybeam = L*sin(thetaTrajectory(1));
Xbeam = [-xbeam,xbeam];
Ybeam = [-ybeam,ybeam];
Xball = rTrajectory(1)*cos(thetaTrajectory(1));
Yball = rTrajectory(1)*sin(thetaTrajectory(1));

figure;hold on;grid on;
Beam = plot(Xbeam,Ybeam,'LineWidth',4,'Color','b');
plot(0,0,'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',8)
Ball = plot(Xball,Yball,'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','r','MarkerSize',8);
axis([-1.2, 1.2, -0.7, 0.7]);
xlabel('x [m]');ylabel('y [m]');

%%
for i = 2:1:length(time)
  xbeam = L*cos(thetaTrajectory(i));
  ybeam = L*sin(thetaTrajectory(i));
  Xbeam = [-xbeam,xbeam];
  Ybeam = [-ybeam,ybeam];
  Xball = rTrajectory(i)*cos(thetaTrajectory(i));
  Yball = rTrajectory(i)*sin(thetaTrajectory(i));

  set(Beam, 'XData', Xbeam);
  set(Beam, 'YData', Ybeam);
  set(Ball, 'XData', Xball);
  set(Ball, 'YData', Yball);
  
  pause(ts)
  drawnow
end