% Ver 11-29-15 Brian
%% Output transposed block of ramp data only
% This script selects a column of data from all studies in a 
% working directory, then outputs it all in a single copy-
% paste-able block.

% Usage:
% Replace keyword with the study phase. If you want additional
% granularity in the output, you can uncomment the variable
% keyword2 and replace it with the phrase of your choice.
% 	e.g. keyword2 = 'AmMa'

% To select final 2 minutes of baseline data for copying,
% uncomment the code under: 
% 	"% Select last 120 seconds for baseline data""


%% Identify files of interest

% Reset environment
clear all

% File extension
fileExtension = '*.csv';

% Keywords (e.g. study phase)
keyword = 'Baseline';
%keyword2 = 'AnSa';

% Column of data to select
col = 3;

% Collecting only last 120 seconds?
baseln = true

% Max number of data points per study for variable of interest
numData = 5000; % Some arbitrarily large value

% Generate file list
fileType = dir(fileExtension);

% Initialize index of files of interest
idxAllFiles        = 1:size(fileType,1);
idxFilesOfInterest = false(size(fileType,1),1);

% Check if each file has keywords in its filename
for iStudy = 1:length(fileType)
    % If any filename includes the keyword
    if any(strcmp(strsplit(fileType(iStudy,1).name,' '),keyword))
        % Check for keyword 2, if it exists
        if exist('keyword2','var') == 1
			if any(strcmp(strsplit(fileType(iStudy,1).name,' '),keyword2)) 
                % Mark studies that have the keyword
                idxFilesOfInterest(iStudy) = true;
                
			end
		else
			% Mark studies that have the keyword
            idxFilesOfInterest(iStudy) = true;
            
        end % end keyword2 conditional 
    end % end keyword1 conditional
end % end file loop

% Warning if keyword not found
if all(~idxFilesOfInterest)
    warning('No selected filetype with keyword(s) found')
end

%% Collect data from all files of interest 

% Initialize a cell array of interest +1 for study label
datablock = cell(size(fileType,1),numData+1);

% Loop over all files of interest (within filetype) in the directory
for iFilesOfInterest = 1:length(fileType)
    % Select variable column of interest
    if idxFilesOfInterest(iFilesOfInterest) == true
        importedFile = importdata(fileType(iFilesOfInterest).name);
        data = importedFile.data(:,col);
        data = num2cell(transpose(data)); 

    % Select last 120 seconds for baseline data
    if baseln == true
      if size(data,2)>=12
      	data = data((end-11):end); 
    	else
    	  warning('Study found with <12 data points')
      end
    end % end baseline conditional
    
    % Enter study data into cell array shifted 1 col for study label
    datablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    datablock(iFilesOfInterest,2:size(data,2)+1) = data;
    
    end % end file-of-interest conditional
end % end file loop

% Clean up cell array by removing empty rows
datablock(all(cellfun(@isempty,datablock),2), : ) = [];

%% Write cell array to an excel workbook file 
xlswrite(strcat('output',keyword,'.xlsx'),datablock);
