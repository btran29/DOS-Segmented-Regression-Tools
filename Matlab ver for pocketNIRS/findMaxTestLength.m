function [ maxrowlength ] = findMaxTestLength( datablock )
%FINDMAXTESTLENGTH Given a cell array, find row with most columns of non
% empty cells
% In other words, given a data block, find the testing session with the
% longest study

% Initialize variable of interest
maxrowlength = 0;   

% Loop over each study
for iRow = 1:size(datablock,1)
    currentRowLength = find(...
        ~cellfun('isempty',datablock(iRow,:)),1,'last');
    if currentRowLength > maxrowlength
        maxrowlength = currentRowLength;
    end
    clearvars currentRowLength
end

end

