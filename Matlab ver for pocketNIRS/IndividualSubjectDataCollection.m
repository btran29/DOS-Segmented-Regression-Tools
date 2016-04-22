% Script to put together all subject data in a single compiled workbook
% Input: datablock tables from outputDataBlockPocketNIRS.m
% Output: compiled cell arrays of data from each subject


%% Get output files in directory
% open file/close files here
% Possible errors:
% Cannot have temporary xlsx files in the same directory, for example, from
% a result from having the xlsx file open

% Specify input sheet num
sheetNum = 4;
    % Reference
    % sheetNum = 1 = binned optical data
    % sheetNum = 4 = 3-minute interval data, set timeAxisInterval = 180
    % sheetNum = 5 = peakVO2 related data

% Specify file name of output workbook
outputFileName = 'dataBySubject_3min.xlsx';

% Select all files with a common identifier in the file-name
fileIdentifier = 'pocket_nirs*';
filesOfInterest = dir(fileIdentifier);
numberOfFiles = length(filesOfInterest);

% Specify time axis interval (for regeneration of time axis if present)
timeAxisInterval = 180;
% Label in workbooks to be compiled that denotes a continuous time axis
timeLabel = 'Time(sec)';
% Label in workbooks that denotes a general list of variables
generalLabel = 'ObsNames';


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
    
    % Import data from sheet
    [workbooksNum{iFile,1},~,workbooksRaw{iFile,1}] = xlsread(...
        filesOfInterest(iFile).name,sheetNum);
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
% For a given row from all imported workbooks, compile the rows into a new
% array.

% Required inputs
workbooksNum; % nested cell array; contains numerical data of interest
initialParticipantList; % cell array; subject list from a workbook
numberOfFiles; % int; number of workbooks
numberOfParticipants; % int taken from size of intialParticipantList
% only if data is continuous
timeAxisInterval; % int; interval between data (used to generate new time axis)

% Create a collection variable for individual participant data
SubjectData = cell(numberOfParticipants,1);

% Select data from particular row within a particular workbook
for iParticipant = 1:numberOfParticipants
for iWorkbook = 1:numberOfFiles
    
% Select data based on type axis present
% Assuming time axis is in multiples of binning interval
firstRowTest = workbooksNum{1,1}(1,:);
firstRowTest = firstRowTest-firstRowTest(1);
if isequal(firstRowTest,0:timeAxisInterval:length(firstRowTest)*timeAxisInterval-1)
    % select data offset for time
    currentData = workbooksNum{iWorkbook,1}(iParticipant+1,:); 
else
    currentData = workbooksNum{iWorkbook,1}(iParticipant,:); 
    
end

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

% If subject does not have data, leave blank
if isempty(currentData)
    continue
end

% Assign time axis if time label is present
if isequal(timeLabel,workbooksRaw{1,1}{1,1})
    % Assign Time axis once per subject after data is located
    currentTimeAxis = 0:timeAxisInterval:currentNumberOfDataPoints*timeAxisInterval-1;
    currentTimeAxis = num2cell(currentTimeAxis);
    SubjectData{iParticipant}(2:end,1) = currentTimeAxis;
end

% Assign general labels from workbook if present
if isequal(generalLabel,workbooksRaw{1,1}{1,1})
    SubjectData{iParticipant}(2:end,1) = workbooksRaw{1,1}(1,2:end);
end

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

% Replace Channel numbers in headers with 'right' or 'left'

% % Rules for PAMP1
% % Remove common terms in the file name
% headers = strrep(headers,'CH1','Left');
% headers = strrep(headers,'CH2','Right');

% Rules for FSHR Cohort 5 and PAMP2
% Remove common terms in the file name
headers = strrep(headers,'CH1','Right');
headers = strrep(headers,'CH2','Left');


for iParticipant = 1:numberOfParticipants
    SubjectData{iParticipant,1}(1,1:end) = headers;
    % should throw an error if there is a mismatch with headers
end


%% Output logic
% Sample format: 'long' form data with cleaned up file names as column
% headers, as well as a new column for time

% Required inputs
numberOfParticipants; % int taken from size of intialParticipantList
initialParticipantList; % cell array of subjects from a workbook
SubjectData; % nested cell array of subject data
outputFileName; % output file name


%% Clean up participant names via regex
% Get some characters after Marshall and use it for subject naming
% pocket_nirs_log_20150223_11.54.02.Marshall1002SM_CH1.left_CH2.right_WR20.PNI

% % % PAMP1
% % expression = 'Marshall';
% % % Initialize collection variable
% % processedParticipantList = cell(numberOfParticipants,1);
% % 
% % % Clean up file name to isolate participant ID
% % for iParticipant = 1:numberOfParticipants
% %     % Locate approx where the participant ID is
% %     idx = regexp(initialParticipantList{iParticipant},expression);
% %     % Assign to collection variable
% %     processedParticipantList{iParticipant} = ...
% %         initialParticipantList{iParticipant}(...
% %         idx+length(expression):idx+length(expression)+7);
% %     % Remove periods
% %     processedParticipantList{iParticipant} = ...
% %         strrep(processedParticipantList{iParticipant},'.','');
% %     % Remove '_C' (the beginning of _CH1 or _CH2)
% %     processedParticipantList{iParticipant} = ...
% %         strrep(processedParticipantList{iParticipant},'_C','');
% %     % Remove remaining underscores
% %     processedParticipantList{iParticipant} = ...
% %         strrep(processedParticipantList{iParticipant},'_','');
% % end

% % FSHR Cohort 5
% expression = '_C.1';
% % Initialize collection variable
% processedParticipantList = cell(numberOfParticipants,1);
% 
% % Clean up file name to isolate participant ID
% for iParticipant = 1:numberOfParticipants
%     % Locate approx where the participant ID is
%     idx = regexp(initialParticipantList{iParticipant},expression);
%     % Assign to collection variable
%     processedParticipantList{iParticipant} = ...
%         initialParticipantList{iParticipant}(...
%         idx-length(expression)-5:idx);
%     % Remove underscores
%     processedParticipantList{iParticipant} = ...
%         strrep(processedParticipantList{iParticipant},'_','');
%     % Get last 5 characters
%     processedParticipantList{iParticipant} = ...
%         processedParticipantList{iParticipant}(end-4:end);
% end

% PAMP Cohort 2
% Initialize collection variable
processedParticipantList = cell(numberOfParticipants,1);

% Clean up file name to isolate participant ID
for iParticipant = 1:numberOfParticipants
    % Get first 7 characters
    processedParticipantList{iParticipant} = ...
        initialParticipantList{iParticipant}(1:7);
    % Remove underscores
    processedParticipantList{iParticipant} = ...
        strrep(processedParticipantList{iParticipant},'_','');    
end

%% Output workbook and rename sheets
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
