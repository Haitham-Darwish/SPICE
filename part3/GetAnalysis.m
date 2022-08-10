function [analysis map] = GetAnalysis(netlist)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

analysis={};
sweep_type=[];
points_value=0;
start_frequency=[];
end_frequency=[];
map=[];

%__Part 1__
%We loop starting from line_number = 2 to skip the title (the first line)
for line_number = 2:1:numel(netlist)
    line = netlist{line_number};
    
    %Split the line at spaces
    splitted_line = strsplit(line);
    %Remove the empty cells due to strsplit function
    splitted_line = splitted_line(~cellfun('isempty',splitted_line));
    %Check if the first letter in the line matches the key
   if isempty(splitted_line)
    continue
   end
    if upper(splitted_line(1)) == ".AC"
        analysis=[analysis "AC"];
        %Splitted_line = 'Name' 'Node_1' 'Node_2' 'Value'
        %Append each cell to its vector
        sweep_type=splitted_line(2);
        points_value=splitted_line(3);
        start_frequency=splitted_line(4);
        end_frequency=splitted_line(5);
    end

    if upper(splitted_line(1)) == ".OP"
        analysis=[analysis "OP"];
    end

end

if ismember('AC', analysis)
    %Prefixes map
    symbols = {'f', 'p', 'n', 'u', 'm', 'k', 'meg', 'g', 't'};
    factors = [1e-15 1e-12 1e-9 1e-6 1e-3 1e3 1e6 1e9 1e12];

    start_frequency=strrep(lower(start_frequency), 'hz', '');
    end_frequency=strrep(lower(end_frequency), 'hz', '');
    %Add 000 to avoid errors in the checking processes
    start_frequency = strcat('000', start_frequency);
    end_frequency = strcat('000', end_frequency);
    %check if it's meg
    checked_prefix = ismember(symbols, lower(start_frequency{1}(end-2:end)));
    if any(checked_prefix)
        start_frequency = str2num(start_frequency{1}(1:end-3)) * factors(checked_prefix);
        start_frequency = num2str(start_frequency);
    end
    
    checked_prefix = ismember(symbols, lower(end_frequency{1}(end-2:end)));
    if any(checked_prefix)
        end_frequency = str2num(end_frequency{1}(1:end-3)) * factors(checked_prefix);
        end_frequency = num2str(end_frequency);
    end
        
    %check if it's any prefix else
    checked_prefix = ismember(symbols, lower(start_frequency(end)));
    if any(checked_prefix)
        start_frequency = str2num(start_frequency(1:end-1)) * factors(checked_prefix);
        start_frequency = num2str(start_frequency);
    end
    
    %check if it's any prefix else
    checked_prefix = ismember(symbols, lower(end_frequency(end)));
    if any(checked_prefix)
        end_frequency = str2num(end_frequency(1:end-1)) * factors(checked_prefix);
        end_frequency = num2str(end_frequency);
    end

    map = containers.Map("AC",{sweep_type, points_value, ...
        start_frequency, end_frequency});
end

end