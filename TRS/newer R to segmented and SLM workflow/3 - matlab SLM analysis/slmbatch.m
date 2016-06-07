% Ver 12-8-15 Brian
%% Run SLM on cleaned up DOS data files
%
% To run, make folders listed under 'Reference sub-directories for 
% easier comparison' in the working directory. SLM must be installed.
% Input keywords of choice in the variable 'keyword'. Working directory
% must contain the data to be analyzed.
% 
% Script assumes HbO2, HbR, THb, stO2 are in columns 2 through 5 of 
% each data file.

%% User input


% Reset environment
clear all

% File extension
fileExtension = '*.csv';

% Keywords (e.g. study phase, subject IDs)
keyword = {'Ramp','Brain'};

% File name delimeter
delimiter = ' ';

% Columns to run SLM tool on
columns = 2:5; % select HbO2, HbR, THb, stO2 only

% Reference sub-directories for easier comparison
workingDir = pwd;
mkdir('HbO2')
mkdir('HbR')
mkdir('THb')
mkdir('stO2')
mkdir('slmbreakpoints')
dirHbO2 = [workingDir '\HbO2'];
dirHbR = [workingDir '\HbR'];
dirTHb = [workingDir '\THb'];
dirstO2 = [workingDir '\stO2'];
dirBreakpoints = [workingDir '\slmbreakpoints'];


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

%% Run SLM

% Initialize collection variable for all files
SLMdata = cell(length(idxFilesOfInterest(idxFilesOfInterest==true)),1);

% For each file, 
for iFilesOfInterest = 1:length(fileType)
    if idxFilesOfInterest(iFilesOfInterest)
        % Load data
        fileName = strrep(fileType(iFilesOfInterest).name,'.csv','');
        fileName = strrep(fileName,' ','');
        fileData = importdata(fileType(iFilesOfInterest).name);

        % For each column of data,
        for column = columns
            x = fileData.data(:,1); % first column = time
            y = fileData.data(:,column);

            % run SLM
            breakpointData = slmengine(x,y,...
                'plot','off','degree',1,'interior','free','knots',4);

            % output figures
            colHeader = fileData.textdata{column};
            % clean up R output to remove 'data.', and double quotes
            colHeader = strrep(colHeader,'data.','');
            colHeader = strrep(colHeader,'"','');

            % output in specific directory
            switch column
                case 2
                    cd(dirHbO2)
                case 3
                    cd(dirHbR)
                case 4
                    cd(dirTHb)
                case 5
                    cd(dirstO2)
            end
            hold on

            % generate figure
            figFileName = sprintf('SLM Fit for %s - %s',...
                            fileName,colHeader);
                title(figFileName)
                slmFig = plotslm(breakpointData);
                set(gcf,'Visible','off', 'Color', 'w');
                export_fig(figFileName,'-png','-m1.5');
            close all

            % switch back to working (data) directory
            cd(workingDir)

            % output column data into collection variable,
            % shifted left one for time column
            SLMdata.(fileName)(column-1) = breakpointData;

        end
    end
end

%% Output collection variable in a workbook
files = fieldnames(SLMdata);
% for each file,
for file = 1:length(files)
    % initialize a collection variable
    knots = NaN(4);
    
    % for each column of data,
    for column = 1:4
        knotData = SLMdata.(files{file})(column).knots;
        knots(1:length(knotData),column) = knotData;
        
    end
    
    % convert collection variable to cell for xls output
    knots = num2cell(knots);
    
    % Headers
    headers = {'HbO2','HbR','THb','stO2'};
    
    cd([workingDir '\slmbreakpoints'])
    % combine arrays then write
    workbookFileName = [files{file} ' - Breakpoints'];
    xlswrite(workbookFileName,[headers;knots],1);
    cd(workingDir)
end
