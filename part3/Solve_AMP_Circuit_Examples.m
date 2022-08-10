% cleaning the workspace, and cmd window
clear all;
clc;

% running the first SPICE netlist
fprintf('The first netlist:\n');

%for i=1:length(idx)
 
[sum,num]=Solve_AMP_Circuit('unity_gain_feedback_op_amp.cir');
%end


%clear all; % used to bypass an error only with Octave (not MATLAB)

