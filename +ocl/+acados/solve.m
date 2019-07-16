function solve(acados_ocp)

% solve
tic;
acados_ocp.solve();
time_ext = toc;

status = acados_ocp.get('status');
sqp_iter = acados_ocp.get('sqp_iter');
time_tot = acados_ocp.get('time_tot');
time_lin = acados_ocp.get('time_lin');
time_reg = acados_ocp.get('time_reg');
time_qp_sol = acados_ocp.get('time_qp_sol');

fprintf('\nstatus = %d, sqp_iter = %d, time_ext = %f [ms], time_int = %f [ms] (time_lin = %f [ms], time_qp_sol = %f [ms], time_reg = %f [ms])\n', status, sqp_iter, time_ext*1e3, time_tot*1e3, time_lin*1e3, time_qp_sol*1e3, time_reg*1e3);

stat = acados_ocp.get('stat');
fprintf('\niter\tres_g\t\tres_b\t\tres_d\t\tres_m\t\tqp_stat\tqp_iter');
if size(stat,2)>7
  fprintf('\tqp_res_g\tqp_res_b\tqp_res_d\tqp_res_m');
end
fprintf('\n');
for ii=1:size(stat,1)
  fprintf('%d\t%e\t%e\t%e\t%e\t%d\t%d', stat(ii,1), stat(ii,2), stat(ii,3), stat(ii,4), stat(ii,5), stat(ii,6), stat(ii,7));
  if size(stat,2)>7
    fprintf('\t%e\t%e\t%e\t%e', stat(ii,8), stat(ii,9), stat(ii,10), stat(ii,11));
  end
  fprintf('\n');
end
fprintf('\n');

if status==0
  fprintf('\nsuccess!\n\n');
else
  fprintf('\nsolution failed!\n\n');
end
