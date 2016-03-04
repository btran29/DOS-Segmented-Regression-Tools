% Ver 3-2-16 Brian
%% Output transposed block of a column of data from studies w/ keywords
% This script selects a column of data from all studies in a 
% working directory, then outputs it all in a single copy-
% paste-able block in a workbook named after the first search term.

% Usage
% Set keyword to a study phase: e.g. keyword = {'Baseline'}. For
% multiple keywords, make it a list, e.g. keyword = {'Baseline',
% 'Brain', 'AnSa'}. Keywords can be anything in the file name,
% as long as it is separated on both sides by the delimiter,
% e.g. an empty space ' ' or an underscore '_'.

% To select final 2 minutes of baseline data for copying,
% set last2min to 'true' (without apostrophes, case 
% sensitive).


%% User input

% Reset environment
clear all

% File extension (e.g. '*.xls' or '*.csv'
fileExtension = '*.PNI';

% Keyword (e.g. study phase, subject IDs,)
keyword = {'Marshall'};

% Additional label for the output (e.g. keywords, variable of interest
% in the column of data to select)
label = 'CH1_delta_oxy-Hb_(au)';

% Column of data to select
col = 7; 
% column 7 = CH1_?[oxy-Hb](a.u.)
% column 8 = CH1_?[deoxy-Hb](a.u.)	
% column 9 = CH1_?[total-Hb](a.u.)

% Filename of output xslx
outputFileName = strcat('collected ',keyword{1},' ',label,'.xlsx');

% Select last 12 samples
last2min = false; % true or false, case sensitive

% Max number of data points per study for variable of interest
numData = 500; % Some arbitrarily large value


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
        if any(strfind(fileType(iStudy).name,keyword{iKeywordList}))
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


%% Generate user input list for locating beginning ramp markers


%% Collect data from all files of interest 

% Initialize a cell array of interest +1 for study label
datablock = cell(size(idxFilesOfInterest,1),numData+1);
% TODO: fix data block assignment, numData =! binMeans

% Loop over all files of interest (within filetype) in the directory
for iFilesOfInterest = 1:length(fileType)
    % Select variable column of interest, transpose
    if idxFilesOfInterest(iFilesOfInterest)
        try
            % Import data
            importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
            data = importedFile.data(:,col); % col references ignore cnt/dateTime
            time = importedFile.data(:,1); % fixed % column 1
            events = importedFile.data(:,2); % fixed @ column 2
            
            % Locate ramp and bin from there
            
            % Binning procedure %
            binMeans = unequalsizedbins(10,data,time);
                       
            % Transpose bin means
            binMeans = transpose(binMeans);
    
	
            % Select last 120 seconds for baseline data %
            if last2min
                if size(data,2)>=12 %#ok<UNRCH> % manually set true/false
                    data = data((end-11):end); 
                end
            end
            
            
        catch
            warning('Missing data - %s',fileType(iFilesOfInterest).name)
            continue
        end
    % Enter study data into cell array shifted 1 col for study label
    datablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    datablock(iFilesOfInterest,2:(size(binMeans,2)+1)) = num2cell(binMeans);
    
    end % end file-of-interest conditional
end % end file loop

% Clean up cell array by removing empty rows
datablock(all(cellfun(@isempty,datablock),2), : ) = [];

%% Write cell array to an excel workbook file 
xlswrite(outputFileName,datablock,1,'A2');