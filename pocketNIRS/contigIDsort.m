function [ output ] = contigIDsort( input )
%contigIDsort Creates contiguous ID axis, sorts cell array into new ID axis
%   Requires cell array input

%% Determine if there is a label row
if ischar(input{1,2}) == 1 || isequal(fix(input{1,2}),input{1,2}) % whole #
    haslabels = true;
elseif ischar(input{1,2}) == 0
    haslabels = false;
end

%% If data block has labels skip one row
if haslabels == true
    startRow = 2;
elseif haslabels == false
    startRow = 1;
end

%% Grab old axis
inputAxis = input(2:end,1);
inputAxis_sorted = sort(inputAxis);

%% New Axis
startID = str2double(input{startRow,1});
endID = str2double(inputAxis_sorted{end});
IDlist = transpose(startID:endID);

%% Create output array
outputHeight = size(IDlist,1) + (startRow-1);
outputWidth = size(input,2);
output = cell(outputHeight,outputWidth);

%% Transfer labels and new ID axis into output array
if haslabels == true
    output(1,1:end) = input(1,1:end); % via cell values, not raw
end
output(startRow:end,1) = num2cell(transpose(IDlist));

%% Sort input data into output array
for iRow = startRow:size(input,1)
    % Grab data for a particular row
    rowData = input(iRow,2:end); % cell
    rowLabel = str2double(input{iRow,1}); % raw, not cell
    
    % Does the label match output?
    for iRowOutput = startRow:size(output,1)
        if rowLabel == output{iRowOutput,1}
            matchedRow = iRowOutput;
        end
    end
    
    % Transfer data to appropriate row
    output(matchedRow,2:end) = rowData; % via cell values
end


end

