% Ver 12-5-15 Brian
%% Output transposed block of a column of data from studies w/ keywords
% This script selects a column of data from all studies in a 
% working directory, then outputs it all in a single copy-
% paste-able block in a workbook named after the first search term.

% Usage:
% Set keyword to study phase: e.g. keyword = {'Baseline'}. For
% multiple keywords, make it a list, e.g. keyword = {'Baseline',
% 'Brain', 'AnSa'}.

% To select final 2 minutes of baseline data for copying,
% set last2min to 'true' (without apostrophes, case 
% sensitive).


%% User input

% Reset environment
clear all

% File extension
fileExtension = '*.csv';

% Keywords (e.g. study phase, subject IDs)
keyword = {'Baseline','Brain','AnSa'};

% Column of data to select
col = 3;

% Select last 12 samples
last2min = true; % true or false, case sensitive

% File name delimeter
delimiter = ' ';

% Max number of data points per study for variable of interest
numData = 5000; % Some arbitrarily large value


%% Identify files of interest
% Generate file list
fileType = dir(fileExtension);

% Initialize index of files of interest
idxFilesOfInterest = false(size(fileType,1),1);

% Check if each file has keywords in its filename
for iStudy = 1:length(fileType)

% Initilize match list of keywords for each study
matchList = false(length(keyword),1);

    % Loop through all keywords, mark if study matches keyword
    for iKeywordList = 1:length(matchList)

        % Split filename into keywords by delimeter and compare
        if any(strcmp(strsplit(fileType(iStudy,1).name,delimiter),keyword(iKeywordList)))
            matchList(iKeywordList) = true;
        end
    end

    % Mark studies that have the keyword
    if all(matchList)
        idxFilesOfInterest(iStudy) = true;
    end
 
end % end file loop

% Warning if keyword not found
if all(~idxFilesOfInterest)
    warning('No selected filetype with keyword(s) found')
    return
end

%% Collect data from all files of interest 

% Initialize a cell array of interest +1 for study label
datablock = cell(size(fileType,1),numData+1);

% Loop over all files of interest (within filetype) in the directory
for iFilesOfInterest = 1:length(fileType)
    % Select variable column of interest, transpose
    if idxFilesOfInterest(iFilesOfInterest)
        importedFile = importdata(fileType(iFilesOfInterest).name);
        data = importedFile.data(:,col);
        data = num2cell(transpose(data)); 
	
        % Select last 120 seconds for baseline data
        if last2min
            if size(data,2)>=12
                data = data((end-11):end); 
            end
        end
        
    % Enter study data into cell array shifted 1 col for study label
    datablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    datablock(iFilesOfInterest,2:size(data,2)+1) = data;
    
    end % end file-of-interest conditional
end % end file loop

% Clean up cell array by removing empty rows
datablock(all(cellfun(@isempty,datablock),2), : ) = [];

%% Write cell array to an excel workbook file 
xlswrite(strcat('output',keyword{1},'.xlsx'),datablock);
