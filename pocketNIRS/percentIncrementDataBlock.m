function [ percentDataBlock ] = percentIncrementDataBlock(...
    dataBlock,percents,numberoftests)
%percentIncrementDataBlock find test data based on % completion
%   
% Locate the associated variable data at % time points for relative
% comparison.
%
% Inputs: 
%   1. number of files of interest, numeric
%   2. binned data after ramp start, cell
%       format: file, data, with testing sessions separated by row
%   3. percent of test to locate data, numeric array
%
% Output: 
%   1. percentDataBlock, cell 
%       format: a table with a session ID for the first column, and data
%       populating columns to the right of the first column. the table will
%       have header labels with time points of interest



% Initialize collection variables
dataArray = zeros(numberoftests,length(percents));

% Collect values over files of interest using a data block
for iRow = 1:size(dataBlock,1);
    % Get current row of numerical data
    currentdata = dataBlock(iRow, 2:end);

    % Clean up data from post ramp start data block
    currentdata(:,all(cellfun(@isempty,currentdata),1)) = [];
    currentdata = cell2mat(currentdata);

    % Grab total index
    lengthCurrentData = length(currentdata);

   
    % Loop over each percent, if present
    for iPercent = 1:length(percents);

        % Get current percentage and index of interest
        currentPercent = percents(iPercent);
        currentIndex = ceil(currentPercent*0.01*lengthCurrentData);
        
        % Use first data point for 0% percent
        if currentIndex == 0
            currentIndex = 1;
        end 
        
        % Get value at percent of total index
        currentValue = currentdata(currentIndex);
                        
        % Assign into a data array
        dataArray(iRow,iPercent) = currentValue;
    end
end

% Labels 
percentlabels = cell(1,length(percents));
for iLabel = 1:length(percents);
    percentlabels{iLabel} = sprintf('%d%%',percents(iLabel));
end
sessionlabels = [cellstr('ObsNames');dataBlock(1:end,1)];

% Combine labels and data for output data block
percentDataBlock = [percentlabels; num2cell(dataArray)];
percentDataBlock = horzcat(sessionlabels,percentDataBlock);

end % end function

