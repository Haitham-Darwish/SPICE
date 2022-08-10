% cleaning the workspace, and cmd window
clear all;
clc;

% running the first SPICE netlist
fprintf('The first netlist:\n');
[sum,num]=Solve_Circuit('circuit_1.cir');

clear all; % used to bypass an error only with Octave (not MATLAB)


fprintf('The second netlist:\n');

[sum,num]=Solve_Circuit('circuit_2.cir');

clear all; % used to bypass an error only with Octave (not MATLAB)

