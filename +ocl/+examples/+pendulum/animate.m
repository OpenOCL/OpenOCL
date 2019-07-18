function animate(l, p_traj, times)

p = p_traj(:,1);

figure;
plot(0,0,'ob', 'MarkerSize', 22)
hold on

h_line = plot([0,p(1)],[0,p(2)],'-k', 'LineWidth', 4);
h_bob = plot(p(1),p(2),'ok', 'MarkerSize', 22, 'MarkerFaceColor','r');
hold off

xlim([-l-0.1,l+0.1])
ylim([-l-0.1,l+0.1])

for k=1:size(p_traj, 2)-1
  tic;
  p = p_traj(:,k);
  
  set(h_line, 'XData', [0 p(1)]);
  set(h_line, 'YData', [0 p(2)]);
  
  set(h_bob, 'XData', p(1));
  set(h_bob, 'YData', p(2));
  
  pause(times(k+1)-times(k) - toc);
end

p = p_traj(:,end);

set(h_line, 'XData', [0 p(1)]);
set(h_line, 'YData', [0 p(2)]);

set(h_bob, 'XData', p(1));
set(h_bob, 'YData', p(2));

