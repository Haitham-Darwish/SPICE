% cleaning the workspace, and cmd window
clear all;
clc;

% running the first SPICE netlist
fprintf('The first netlist:\n');

%for i=1:length(idx)
 
[sum,num, map]=Solve_AC_Circuit('underdamped.cir');
%end


%clear all; % used to bypass an error only with Octave (not MATLAB)

