function [symbolic_ans, numeric_ans] = Solve_AMP_Circuit(netlist_directory)

%{
Part 1: reading the netlist
Part 2: parsing the netlist
Part 3: creating the matrices
Part 4: solving the matrices
%}

%__Part 1__

%loading netlist
raw_netlist = fopen(netlist_directory);
raw_netlist = fscanf(raw_netlist, '%c');
%Deleting multiple spaces, etc. using regular expressions
netlist = regexprep(raw_netlist,' *',' ');
netlist = regexprep(netlist,' I','I');
netlist = regexprep(netlist,' R','R');
netlist = regexprep(netlist,' V','V');
netlist = regexprep(netlist,' C','C');
netlist = regexprep(netlist,' L','L');
netlist = regexp(netlist,'[^\n]*','match');

netlist=GetSubckt(netlist);
[analysis map] = GetAnalysis(netlist);

%__Part 2__
%You may visit "ParseNetlist.m"
[R_Node_1 R_Node_2 R_Values R_Names] = ParseNetlist(netlist, 'R');
[V_Node_1 V_Node_2 V_Values V_Names] = ParseNetlist(netlist, 'V');
[I_Node_1 I_Node_2 I_Values I_Names] = ParseNetlist(netlist, 'I');
[C_Node_1 C_Node_2 C_Values C_Names] = ParseNetlist(netlist, 'C');
[L_Node_1 L_Node_2 L_Values L_Names] = ParseNetlist(netlist, 'L');

[E_Node_n_plus E_Node_n_minus E_Node_nc_plus E_Node_nc_minus ...
  E_Values E_Names]=ParseDep(netlist, 'E');
[G_Node_n_plus G_Node_n_minus G_Node_nc_plus G_Node_nc_minus ...
  G_Values G_Names]=ParseDep(netlist, 'G');
%Counting nodes
%Nodes should be named in order 0, 1, 2, 3, ..
%We will combine all parsed nodes, then find the maximum number which is
%the number of nodes assuming that they are named in order

nodes_list = [R_Node_1 R_Node_2 V_Node_1 V_Node_2 I_Node_1 I_Node_2 ...
               C_Node_1 C_Node_2 L_Node_1 L_Node_2 ...
               E_Node_n_plus E_Node_n_minus E_Node_nc_plus E_Node_nc_minus ...
               G_Node_n_plus G_Node_n_minus G_Node_nc_plus G_Node_nc_minus];
nodes_number = max(str2double(nodes_list));


%__Part 3__
%Matrices_size = no. nodes + no. Vsources
matrices_size = nodes_number + numel(V_Names)+numel(E_Names);

%Z matrix
%Initialize zero matrix
unit_matrix = cell(matrices_size, 1);
for i = 1:1:numel(unit_matrix)
    unit_matrix{i} = ['0'];
end
z = unit_matrix;

%stamping Isources
for I = 1:1:numel(I_Names)
    current_node_1 = str2double(I_Node_1(I));
    current_node_2 = str2double(I_Node_2(I));
    current_name = I_Names{I};
    if current_node_1 ~= 0
        z{current_node_1} = [z{current_node_1} '-' current_name];
    end
    if current_node_2 ~= 0
        z{current_node_2} = [z{current_node_2} '+' current_name];
    end
end
%stamping Vsources
for V = 1:1:numel(V_Names)
    z{nodes_number + V} = [V_Names{V}];
end
Z = str2sym(z);
    
%X matrix
x = cell(matrices_size, 1);
for node = 1:1:nodes_number
    x{node} = ['V_' num2str(node)];
end
%Stamping Vsources
for V = 1:1:numel(V_Names)
    x{nodes_number + V} = ['I_' V_Names{V}];
end

for E = 1:1:numel(E_Names)
    x{nodes_number + numel(V_Names) +E} = ['0'];
end

X = str2sym(x);

%A matrix
%_G matirix
G = repmat(unit_matrix(1:nodes_number), 1, nodes_number);
%Stamping R
for R = 1:1:numel(R_Names)
    current_node_1 = str2double(R_Node_1(R));
    current_node_2 = str2double(R_Node_2(R));
    current_name = R_Names{R};
    if current_node_1 ~= 0
        G{current_node_1, current_node_1} = [G{current_node_1, current_node_1} '+1/' current_name];
    end
    if current_node_2 ~= 0
        % add a line here to assign an element in G matrix
        G{current_node_2, current_node_2} = [G{current_node_2, current_node_2}  '+1/' current_name];
    end
    if current_node_1 ~= 0 && current_node_2 ~= 0
        % add a line here to assign an element in G matrix
        % add a line here to assign an element in G matrix
        G{current_node_1, current_node_2} = [G{current_node_1, current_node_2} '-1/' current_name];
        G{current_node_2, current_node_1} = [G{current_node_2, current_node_1} '-1/' current_name];
    end
end

%Stamping C
for C = 1:1:numel(C_Names)
    cap_node_1 = str2double(C_Node_1(C));
    cap_node_2 = str2double(C_Node_2(C));
    cap_name = C_Names{C};
    if cap_node_1 ~= 0
        G{cap_node_1, cap_node_1} = [G{cap_node_1, cap_node_1} '+' 'i*w*' cap_name];
    end
    if cap_node_2 ~= 0
        % add a line here to assign an element in G matrix
        G{cap_node_2, cap_node_2} = [G{cap_node_2, current_node_2}  '+' 'i*w*' cap_name];
    end
    if cap_node_1 ~= 0 && cap_node_2 ~= 0
        % add a line here to assign an element in G matrix
        % add a line here to assign an element in G matrix
        G{cap_node_1, cap_node_2} = [G{cap_node_1, cap_node_2} '-' 'i*w*' cap_name];
        G{cap_node_2, current_node_1} = [G{cap_node_2, cap_node_1} '-' 'i*w*' cap_name];
    end
end

%Stamping L
for L = 1:1:numel(L_Names)
    L_node_1 = str2double(L_Node_1(L));
    L_node_2 = str2double(L_Node_2(L));
    L_name = L_Names{L};
    if current_node_1 ~= 0
        G{L_node_1, L_node_1} = [G{L_node_1, L_node_1} '+1/' '(i*w*' L_name ')'];
    end
    if L_node_2 ~= 0
        % add a line here to assign an element in G matrix
        G{L_node_2, L_node_2} = [G{L_node_2, L_node_2}  '+1/' '(i*w*' L_name ')'];
    end
    if L_node_1 ~= 0 && L_node_2 ~= 0
        % add a line here to assign an element in G matrix
        % add a line here to assign an element in G matrix
        G{L_node_1, L_node_2} = [G{L_node_1, L_node_2} '-1/' '(i*w*' L_name ')'];
        G{L_node_2, L_node_1} = [G{L_node_2, L_node_1} '-1/' '(i*w*' L_name ')'];
    end
end

%Stamping VCCS
for VCCS = 1:1:numel(G_Names)
    G_Node_n_plus = str2double(G_Node_n_plus(VCCS));
    G_Node_n_minus = str2double(G_Node_n_minus(VCCS));
    G_Node_nc_plus = str2double(G_Node_nc_plus(VCCS));
    G_Node_nc_minus = str2double(G_Node_nc_minus(VCCS));
    G_name = G_Names{VCCS};
       
    if G_Node_n_plus ~= 0 && G_Node_nc_plus ~= 0
        G{G_Node_n_plus, G_Node_nc_plus} = [G{G_Node_n_plus, G_Node_nc_plus} '+'  G_name];
    end
    
    if G_Node_n_plus ~= 0 && G_Node_nc_minus ~= 0
        G{G_Node_n_plus, G_Node_nc_minus} = [G{G_Node_n_plus, G_Node_nc_minus} '-'  G_name];
    end
    
    if G_Node_n_minus ~= 0 && G_Node_nc_minus ~= 0
        G{G_Node_n_minus, G_Node_nc_minus} = [G{G_Node_n_minus, G_Node_nc_minus} '+'  G_name];
    end
    
    if G_Node_n_minus ~= 0 && G_Node_nc_plus ~= 0
        G{G_Node_n_minus, G_Node_nc_plus} = [G{G_Node_n_minus, G_Node_nc_plus} '-'  G_name];
    end
    
end
%Stamping VCVS
B2=repmat(unit_matrix, 1, numel(E_Names));
C2=repmat(unit_matrix, 1, numel(E_Names))';
for VCVS = 1:1:numel(E_Names)
    E_Node_n_plus = str2double(E_Node_n_plus(VCVS));
    E_Node_n_minus = str2double(E_Node_n_minus(VCVS));
    E_Node_nc_plus = str2double(E_Node_nc_plus(VCVS));
    E_Node_nc_minus = str2double(E_Node_nc_minus(VCVS));
    E_name = E_Names{VCVS};
    
    if E_Node_n_plus ~= 0
        C2{VCVS, E_Node_n_plus} = [C2{VCVS, E_Node_n_plus} '+'  '1'];
        B2{E_Node_n_plus, VCVS} = [B2{E_Node_n_plus, VCVS} '+'  '1'];
    end
    
    if E_Node_n_minus ~= 0
        C2{VCVS, E_Node_n_minus} = [C2{VCVS, E_Node_n_minus} '+'  '1'];
        B2{E_Node_n_minus, VCVS} = [B2{E_Node_n_minus, VCVS} '+'  '1'];
    end
    
    if E_Node_nc_plus ~= 0
        C2{VCVS, E_Node_nc_plus} = [C2{VCVS, E_Node_nc_plus} '-'  E_name];
    end
    
    if E_Node_nc_minus ~= 0
        C2{VCVS, E_Node_nc_minus} = [C2{VCVS, E_Node_nc_minus} '+'  E_name];
    end
end

%B matrix
B = repmat(unit_matrix, 1, numel(V_Names));
%Stamping Vsource
for V = 1:1:numel(V_Names)
    current_node_1 = str2double(V_Node_1(V));
    current_node_2 = str2double(V_Node_2(V));
    if current_node_1 ~= 0
        % add a line here to assign an element in B matrix
        B{current_node_1, V} = [B{current_node_1, V} '+' '1'];
    end
    if current_node_2 ~= 0
        % add a line here to assign an element in B matrix
        B{current_node_2, V} = [B{current_node_2, V} '-' '1'];
    end
end

%C matrix
C = B.';
B=[B B2];
C=[C;C2];

%Combining all in A matrix
a = [G; C(:,1:nodes_number)];
a = [a B]

A = str2sym(a);
%__Part 4__
%Symbolic
symbolic_ans = A\Z
%Numeric
%Fetch variables values
for R=1:1:numel(R_Names)
    eval([R_Names{R} ' = ' num2str(R_Values{R}) ';']);
end

for C=1:1:numel(C_Names)
    eval([C_Names{C} ' = ' num2str(C_Values{C}) ';']);
end

for L=1:1:numel(L_Names)
    eval([L_Names{L} ' = ' num2str(L_Values{L}) ';']);
end

for V=1:1:numel(V_Names)
    % add a line here to assign voltage sources values into double variables
    eval([V_Names{V} ' = ' num2str(V_Values{V}) ';']);
end

for V=1:1:numel(I_Names)
    % add a line here to assign voltage sources values into double variables
    eval([I_Names{V} ' = ' num2str(I_Values{V}) ';']);
end

for vcvs=1:1:numel(E_Names)
   % add a line here to assign voltage sources values into double variables
    eval([E_Names{vcvs} ' = ' num2str(E_Values{vcvs}) ';']);
end
for vccs=1:1:numel(G_Names)
    % add a line here to assign voltage sources values into double variables
    eval([G_Names{vccs} ' = ' num2str(G_Values{vccs}) ';']);
end

%Substitute
% add a line here to substitute the symoblic solutions with the variables created in the previous step, and save it into num array

V3=[];
numeric_ans=cell(length(symbolic_ans), 1);
for a=1:length(analysis)
    if upper(analysis(a))=="OP"
        eval('w=0');
        
        fprintf('OP:\n');
        numeric_ans=subs(symbolic_ans);
         %Print
        for i = 1:1:numel(symbolic_ans)
            fprintf('%s = %f\n', char(X(i)), double(numeric_ans(i)));
        end
    elseif upper(analysis(a))=="AC"
        ac=map("AC");
        if upper(ac{1})=="DEC"

            start=log10(str2double(ac{3}));
            ends=log10(str2double(ac{4}));
            W = bsxfun(@times, [1:10/str2double(ac{2}):10]', ...
                logspace(start, ...
                ends, ...
                ends-start));
        elseif upper(ac{1})=="LIN"
            start=str2double(ac{3});
            ends=str2double(ac{4});
            W = [1:10/str2double(ac{2}):10];
        elseif upper(ac{1})=="OCT"
            
            start=log2(str2double(ac{3}));
            ends=log2(str2double(ac{4}));
            W = bsxfun(@times, [1:10/str2double(ac{2}):10]', ...
                logspace(start, ...
                ends, ...
                ends-start));

        end
        W = unique(fix(W(:)))*2*pi;
        
        for k=1:length(W)
            w=W(k);
            numeric_ans=subs(symbolic_ans);
        %    numeric_ans(:, k)=numeric;
            V3=[V3 double(numeric_ans(3))];
           
        end
       
        close all;
        figure
        if upper(ac{1})=="DEC"
            semilogx(W/2/pi, mag2db(abs(V3)))

            yticks([-55:5:10])
            yticklabels([-55:5:10] +"dB")
            xticks(10.^[start:ends])
            xlim([start,10^ends])
             ylabel('Magnitude (dB)');
        elseif upper(ac{1})=="LIN"
            plot(W/2/pi, abs(V3))
             ylabel('Magnitude');
        elseif upper(ac{1})=="OCT"
            semilogx(W/2/pi, 2.^(abs(V3)))
            yticks([-55:5:10])
            yticklabels([-55:5:10] +"dB")
            xticks(2.^[start:ends])
            xlim([start,2^ends])
             ylabel('Magnitude (dB)');
        end
        hold on
        
        
        title('Magnitude and Phase VS Frequency');
        xlabel('Frequency (Hz)'); 
       
        yyaxis right
        semilogx(W/2/pi, angle(V3)*180/pi)
        ylabel('Phase (deg)');
        yticks([-200:10:40])
        yticklabels([-200:10:40] +"^o")
        grid
    end
end

    
end
