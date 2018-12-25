# Open Optimal Control Library
<img src="https://openocl.org/imgs/vdp.png" width="30%"> <img src="https://openocl.org/imgs/car.png" width="30%"> <img src="https://openocl.org/imgs/circ.png" width="30%">  
<img src="https://openocl.org/imgs/pend.png" width="30%"> <img src="https://openocl.org/imgs/ballbeam.png" width="30%"> <img src="https://openocl.org/imgs/lemn.png" width="30%">    

## Introduction

The Open Optimal Control Library is a toolbox in Matlab for facilitating modelling and formulation of (parametric) optimal control problems. It interfaces Ipopt [1] to numerically solve the optimal control problems and CasADi [2] to automatically calcuate the necessary derivatives by algorithmic differentiation.

## Quick start

Visit the wiki page for a guide, and have a look the examples:    
https://github.com/JonasKoenemann/optimal-control/wiki

## Models

* airborne wind energy: https://openawe.github.io/
* robotics: https://github.com/JonasKoenemann/openocl_models (very experimental)

## Additional Information

* If you need the moodel to work with MX type variables in your system, you can pass the option "system_casadi_mx" to the solver
* For larger problems it can be beneficial to install HSL linear solvers for ipopt (http://www.hsl.rl.ac.uk/ipopt/) and pass the linear solver name to the solver

## Publications

Performance Assessment of a Rigid Wing Airborne Wind Energy Pumping System  
G. Licitra, J. Koenemann, A. Buerger, P. Williams, R. Ruiterkamp, M. Diehl  
In Energy The International Journal, Elsevier, 2018 (submitted to)

OpenAWE: An Open Source Toolbox for the Optimization of AWE Flight Trajectories  
J. Koenemann, G. Licitra, S. Sieberling, M. Diehl  
In Airborne Wind Energy Conference, Freiburg, 2017

Modeling of an Airborne Wind Energy System with a Flexible Tether Model for the Optimization of Landing Trajectories  
J. Koenemann, P. Williams, S. Sieberling, M. Diehl  
IFAC 2017 World Congress, Toulouse, France. 9-14 July, 2017

Viability Assessment of a Rigid Wing Airborne Wind Energy Pumping System  
G. Licitra, J. Koenemann, G. Horn, P. Williams, R. Ruiterkamp, M. Diehl  
In: 21st International Conference on Process Control (PC), 2017

## References

[1] On the Implementation of a Primal-Dual Interior Point Filter Line Search Algorithm for Large-Scale Nonlinear Programming  
A. Wächter, L.T. Biegler  
Mathematical Programming 106 (2006) 25-57, Available at: https://projects.coin-or.org/Ipopt

[2] CasADi - A software framework for nonlinear optimization and optimal control  
J.A.E. Andersson, J. Gillis, G. Horn, J.B. Rawlings, M. Diehl  
Mathematical Programming Computation, In Press, 2018, Available at: http://casadi.org

## Legal notice

Please see license information in the LICENSE file.
Please contact Jonas.Koenemann [at] yahoo.de for more information.

Dynamic Optimization toolbox
Copyright (C) 2016-2017  Jonas Koenemann

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


This project has received funding from the European Union’s Horizon 2020 research and innovation programme under the Marie Sklodowska-Curie grant agreement No 642682.

Use without warranty.

Jonas Koenemann  
Jonas.Koenemann [at] yahoo.de


