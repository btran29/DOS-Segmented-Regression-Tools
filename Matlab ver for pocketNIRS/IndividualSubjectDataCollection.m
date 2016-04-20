% Script to put together all subject data in a single compiled workbook
% Input: datablock tables from outputDataBlockPocketNIRS.m
% Output: compiled cell arrays of data from each subject


%% Get output files in directory
% open file/close files here
% Possible errors:
% Cannot have temporary xlsx files in the same directory, for example, from
% a result from having the xlsx file open

% Select all files with a common identifier in the file-name
fileIdentifier = 'pocket_nirs*';
filesOfInterest = dir(fileIdentifier);
numberOfFiles = length(filesOfInterest);

% Binning interval (for regeneration of time axis)
binningInterval = 10;

% Initialize collection variable for xlsx import data 
workbooksNum = cell(numberOfFiles,2);
workbooksRaw = cell(numberOfFiles,2); 
    %TODO: just use text data instead instead of raw as the numbers in the
    %raw data currently are not used

% Read excel files
for iFile = 1:numberOfFiles
    % Import entire sheet both as a cell array and as raw numbers 
    % Repeat function call for 10-sec binned data and 3-min intervals data
    % [raw,text,numbers] = xlsread(...);
    [workbooksNum{iFile,1},~,workbooksRaw{iFile,1}] = xlsread(...
        filesOfInterest(iFile).name,1);
    [workbooksNum{iFile,2},~,workbooksRaw{iFile,2}] = xlsread(...
        filesOfInterest(iFile).name,5);
end

%% Double check subject order consistency (in case someone moves a row)
% For a participant list in the very first table, if every name is exactly
% the same move forward with compiling. Otherwise, stop and send an error
% with the location of the mis-match.

% Get initial subject list to compare to
initialParticipantList = workbooksRaw{1,1}(2:end,1);
numberOfParticipants = size(initialParticipantList,1);

% Loop across all workbooks
for iFile = 1:numberOfFiles
    currentParticipantList = workbooksRaw{iFile,1}(2:end,1);
    if isequal(initialParticipantList, currentParticipantList) == false
        error('Inconsistent Subject Order %s\n is different from %s\n',... 
            filesOfInterest(1).name,filesOfInterest(iFile).name);
    end
end
   
%% Compiling logic
% if order consistency is set to TRUE, continue compiling with raw numbers

% Get subject list from a workbook
initialParticipantList;

% Create a collection variable for individual participant data
SubjectData = cell(numberOfParticipants,1);

% Select data from particular row within a particular workbook
for iParticipant = 1:numberOfParticipants
for iWorkbook = 1:numberOfFiles
% Select Data
currentData = workbooksNum{iWorkbook,1}(iParticipant+1,:); % offset for time

% Clean up data to put into a cell array
currentData(:,~any(~isnan(currentData), 1))=[]; % remove NaNs
currentDataCell = num2cell(currentData); % convert to cell

% Create array for data input if not already made
if isempty(SubjectData{iParticipant}) 
    currentNumberOfDataPoints = length(currentData); % for length of array
    SubjectData{iParticipant} = cell(...
        currentNumberOfDataPoints+1,numberOfFiles+1);
end

% Assign data
SubjectData{iParticipant}(2:end,iWorkbook+1) = currentDataCell;
end
% end workbook loop

% Assign Time axis once per subject after data is located
currentTimeAxis = 0:binningInterval:currentNumberOfDataPoints*binningInterval-1;
currentTimeAxis = num2cell(currentTimeAxis);
SubjectData{iParticipant}(2:end,1) = currentTimeAxis;
end % end participant loop

% Create col header collection variable, add time header
headers = cell(1,numberOfFiles+1);
headers{1,1} = 'Time';

% Use modified workbook names for the rest of the headers
for iFile = 1:numberOfFiles
   % Grab the work book file name
   currentHeader = filesOfInterest(iFile).name;
   % Remove common terms in the file name
   currentHeader = strrep(currentHeader,'pocket_nirs_','');
   % Remove file extension
   currentHeader = strrep(currentHeader,'.xlsx','');
   headers{1,iFile+1} = currentHeader;
end

for iParticipant = 1:numberOfParticipants
    SubjectData{iParticipant,1}(1,1:end) = headers;
    % should throw an error if there is a mismatch with headers
end


%% Output logic
% Sample format: 'long' form data with cleaned up file names as column
% headers, as well as a new column for time

outputFileName = 'dataBySubject.xlsx';

% Clean up participant names via regex
% Get some characters after Marshall and use it for subject naming
% pocket_nirs_log_20150223_11.54.02.Marshall1002SM_CH1.left_CH2.right_WR20.PNI

expression = 'Marshall';
% Initialize collection variable
processedParticipantList = cell(numberOfParticipants,1);

% Clean up file name to isolate participant ID
for iParticipant = 1:numberOfParticipants
    % Locate approx where the participant ID is
    idx = regexp(initialParticipantList{iParticipant},expression);
    % Assign to collection variable
    processedParticipantList{iParticipant} = ...
        initialParticipantList{iParticipant}(...
        idx+length(expression):idx+length(expression)+7);
    % Remove periods
    processedParticipantList{iParticipant} = ...
        strrep(processedParticipantList{iParticipant},'.','');
    % Remove '_C' (the beginning of _CH1 or _CH2)
    processedParticipantList{iParticipant} = ...
        strrep(processedParticipantList{iParticipant},'_C','');
    % Remove remaining underscores
    processedParticipantList{iParticipant} = ...
        strrep(processedParticipantList{iParticipant},'_','');
end

% Output workbook and rename sheets
for iParticipant = 1:numberOfParticipants
    % Write to excel sheet
    xlswrite(outputFileName,SubjectData{iParticipant,1},iParticipant);
    % Open ActiveX COM server to rename excel sheets
    e = actxserver('Excel.Application'); 
        ewb = e.Workbooks.Open([pwd '\' outputFileName]);
        ewb.Worksheets.Item(iParticipant).Name = ...
            processedParticipantList{iParticipant};
        ewb.Save
        ewb.Close(false);
        e.Quit
end
