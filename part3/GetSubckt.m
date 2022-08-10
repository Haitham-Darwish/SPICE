function [netlist] = GetSubckt(netlist)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

subckt_names=[];
subckt_nodes={};

X_names=[];
X_nodes={};
raw_netlist=[];
flag=0;

%__Part 1__
%We loop starting from line_number = 2 to skip the title (the first line)
for line_number = 2:1:numel(netlist)
    line = netlist{line_number};
    %Check if the first letter in the line matches the key
    if length(line)<4
        continue
    end
    if upper(line(1:4)) == ".LIB"
        %Split the line at spaces
        splitted_line = strsplit(line);
        %Remove the empty cells due to strsplit function
        splitted_line = splitted_line(~cellfun('isempty',splitted_line));

        raw_netlist = fopen(splitted_line{2});
        raw_netlist = fscanf(raw_netlist, '%c');

        raw_netlist = regexprep(raw_netlist,' *',' ');
        raw_netlist = regexprep(raw_netlist,' I','I');
        raw_netlist = regexprep(raw_netlist,' R','R');
        raw_netlist = regexprep(raw_netlist,' V','V');
        raw_netlist = regexprep(raw_netlist,' C','C');
        raw_netlist = regexprep(raw_netlist,' L','L');
        raw_netlist = regexp(raw_netlist,'[^\n]*','match');


        netlist=[netlist, raw_netlist(2:end)];
    end
end

for line_number = 2:1:numel(netlist)
    line = netlist{line_number};
    %Check if the first letter in the line matches the key
    if length(line)>6
        if lower(line(1:7)) == ".subckt"
            %Split the line at spaces
            splitted_line = strsplit(line);
            %Remove the empty cells due to strsplit function
            splitted_line = splitted_line(~cellfun('isempty',splitted_line));
            if numel(subckt_names)~=0
                subckt_names = {subckt_names splitted_line(2)};
            else
                subckt_names = splitted_line(2);
            end
            
            for i=3:length(splitted_line)
       
                if numel(subckt_nodes)~=0
                    subckt_nodes=[subckt_nodes splitted_line(i)];
                else
                    subckt_nodes=splitted_line(i);
                end
            end

        end
    end
    if upper(line(1))=="X"
        %Split the line at spaces
        splitted_line = strsplit(line);
        %Remove the empty cells due to strsplit function
        splitted_line = splitted_line(~cellfun('isempty',splitted_line));
        if numel(X_names)~=0
            X_names = {X_names splitted_line(5)};
        else
            X_names = splitted_line(5);
        end
        
        for i=2:length(splitted_line)-1
            if numel(X_nodes)~=0
                X_nodes=[X_nodes splitted_line(i)];
            else 
                X_nodes=splitted_line(i);
            end
        end

    end
end
subckt=containers.Map(subckt_names, {subckt_nodes});
X=containers.Map(X_names, {X_nodes});
node1={};
node2={};
for n=1:length(X_names)
   if numel(node1)~=0
       node1=[node1 subckt(X_names{n})];
       node2=[node2 X(X_names{n})];
   else
       node1=subckt(X_names{n});
       node2=X(X_names{n});
   end
end
nodes=containers.Map(node1, node2);

for line_number = 2:1:numel(netlist)
    line = netlist{line_number};
    %Check if the first letter in the line matches the key
    splitted_line = strsplit(line);
    ends=length(splitted_line{1});
    if length(line)>6
        if lower(line(1:7)) == ".subckt"
            flag=1;
        elseif lower(line(1:3)) == "end"
            flag=0;
        end
    end
    if (upper(line(1)) == "R" ||upper(line(1)) == "L" ...
        || upper(line(1)) == "C" || upper(line(1)) == "I") && flag
        
        if ismember(line(ends+2), nodes.keys)
            netlist{line_number}(ends+2)=nodes(line(ends+2));
        end

        if ismember(line(ends+4), nodes.keys)
            netlist{line_number}(ends+4)=nodes(line(ends+4));
        end
           
    end

    if (upper(line(1)) == "E" ||upper(line(1)) == "G") && flag

        if ismember(line(ends+2), nodes.keys)
            netlist{line_number}(ends+2)=nodes(line(ends+2));
        end

        if ismember(line(ends+4), nodes.keys)
            netlist{line_number}(ends+4)=nodes(line(ends+4));
        end
        
        if ismember(line(ends+6), nodes.keys)
            netlist{line_number}(ends+6)=nodes(line(ends+6));
        end

        if ismember(line(ends+8), nodes.keys)
            netlist{line_number}(ends+8)=nodes(line(ends+8));
        end
           
    end
end

end