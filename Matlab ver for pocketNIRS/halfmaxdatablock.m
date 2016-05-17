function [ halfmaxdatablock, peakVO2Err ] = ...
    halfmaxdatablock(numberoftests,...
                     postrampdatablock,...
                     inputhalfpeakVO2time)
%% Generate values highlighting the trajectory of the variable of interest %
% Given a time point of 50% peakVO2, locate the associated variable data at
% that time point and at the start of the exercise challenge.
%
% Inputs: 
%   1. number of files of interest, numeric
%   2. binned data after ramp start, cell
%       format: file, data, with testing sessions separated by row
%   3. time of 50%peakVO2 from input sheet, numeric array
%
% Output: 
%   1. halfmaxdatablock, cell 
%       format: file, data, with testing sessions sessions separated 
%           by row, first row = variable names
%           a table meant for xlsx output

% Initialize collection variables
firstvaluevariable = zeros(numberoftests,1);
halfpeakvariable = zeros(numberoftests,1);
coefvariable = zeros(numberoftests,2);
deltavariable = zeros(numberoftests,1);
% halfpeakVO2datablock = cell(numberoftests+1,5); % unused?

% Collect values over files of interest using postrampdatablock data
for iRow = 1:size(postrampdatablock,1);
    if inputhalfpeakVO2time(iRow) ~= 0 % 0 is default 
        try
            % Assign data if 50% peak VO2 is present
            idx_halfpeakVO2 = ceil(inputhalfpeakVO2time(iRow)*0.1);
            currentdata = postrampdatablock(iRow, 2:end);

            % Clean up data from post ramp start data block
            currentdata(:,all(cellfun(@isempty,currentdata),1)) = [];
            currentdata = cell2mat(currentdata);

            % 0 and 50% peakVO2 values for variable of interest
            firstvaluevariable(iRow) = currentdata(1);
            halfpeakvariable(iRow) = currentdata(idx_halfpeakVO2);

            % Get slope of data from 0 to 50% peakVO2, assuming 10 sec bins
            coefvariable(iRow,1:2) = polyfit(...
                (0:10:10*idx_halfpeakVO2-1),...
                currentdata(1:idx_halfpeakVO2),1);

            % Get delta value from 0 to 50% peakVO2 for data of interest
            deltavariable(iRow,1) = ...
                currentdata(idx_halfpeakVO2) - currentdata(1);
        catch peakVO2Err
           % Put empty values if 50% peak VO2
            firstvaluevariable(iRow) = NaN;
            halfpeakvariable(iRow) = NaN;
            coefvariable(iRow,1:2) = NaN;
            deltavariable(iRow) = NaN;
        end
    else
        % Put empty values if 50% peak VO2 is not present
        firstvaluevariable(iRow) = NaN;
        halfpeakvariable(iRow) = NaN;
        coefvariable(iRow,1:2) = NaN;
        deltavariable(iRow) = NaN;
    end % end conditional that requires 50% peak VO2 time
end % end testing session loop


% Combine data into a block for output
% This style solution will be supported in a future release, dataset might not
%   currently incomplete
% halfmaxdatablock = cell(size(postrampdatablock,1),5);
% halfmaxdatablock(1:end,1) = postrampdatablock(1:end,1);
% halfmaxdatablock{1:end,2:end} = horzcat(firstvaluevariable,...
%                                          halfpeakvariable,...
%                                          coefvariable,...
%                                          deltavariable);
%                                      
slopevariable = coefvariable(:,1);
yintvariable = coefvariable(:,2);
T1 = dataset(firstvaluevariable,halfpeakvariable,...
            slopevariable,yintvariable,deltavariable,...
            'ObsNames',postrampdatablock(1:end,1));
halfmaxdatablock = dataset2cell(T1);
end

