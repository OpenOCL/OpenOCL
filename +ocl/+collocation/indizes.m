function [x_indizes, z_indizes] = indizes(nx,nz,d)
% return the indizes of the states and algebraic states in the
% variables vector

% number of collocation variables at one gridpoint
% (states+algebraic states)
ncv = nx+nz; 

x_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nx-1)', (0:d-1)*ncv+1, 'UniformOutput', false));
z_indizes = cell2mat(arrayfun(@(start_i) (start_i:start_i+nz-1)', (0:d-1)*ncv+nx+1, 'UniformOutput', false));
