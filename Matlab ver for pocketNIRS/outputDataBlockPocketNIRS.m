% Ver 3-9-16 Brian
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
keyword = {'nirs'};

% Additional label for the output (e.g. keywords, variable of interest
% in the column of data to select)
% Must not have spaces, and work as a windows folder name
label = 'CH2_delta_totalHb';

% Column of data to select
col = 18; 
% Channel 1
    % column 7 = CH1_delta_oxyHb_(au)
    % column 8 = CH1_delta_deoxyHb_(au)	
    % column 9 = CH1_delta_totalHb_(au)
% Channel 2
    % column 16 = CH2_delta_oxyHb_(au)
    % column 17 = CH2_delta_deoxyHb_(au)	
    % column 18 = CH2_delta_totalHb_(au)    

% Binning interval, seconds
bininterval = 10; 
    
% Metadata list
inputmetadata = {
    'Keyword Used','Workbook Label','Column Used',...
    'Bin Interval','Date Generated';...
    keyword{1},label,col,bininterval,datestr(now,0);
    'Binning method:', 'pre/post ramp = bin 10 sec raw data from ramp start',...
    'three-minute interval = bin -10 sec raw data from each point',...
    '',''};

% Filename of output xslx
outputFileName = strcat('',keyword{1},'_',label);

% Ouput Unbinned CSV format with ramp start adjusted time
nirs2rampstartcsv = false;

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

% Generate file list array
filelist = fileType(idxFilesOfInterest);
filelist = struct2cell(filelist);
filelist = transpose(filelist(1,:));

% Generate default marker array
markerlist = cell(length(filelist),1);
markerlist(:,1) = {2}; % beginning ramp by default is 2

% Combine arrays
inputlistarray = horzcat(filelist,markerlist);

% Generate headers
headers = {'filename','exeStart'};

% Output to an easily editable workbook + notify in console
inputfilename = 'RampEventMarkers.xlsx';
xlswrite(inputfilename,headers,2,'A1');
xlswrite(inputfilename,inputlistarray,2,'A2');
fprintf('\nGenerated input workbook in current directory.')
fprintf('\nNOTE: New data is in the 2nd sheet to prevent overwriting.\n')


%% Require user input prior to continuing
prompt = '\nHave the markers been located and entered into the input\n workbook? Press enter to continue. \n';
x = input(prompt);


%% Load input marker workbook
rampeventmarkerinput = importdata('RampEventMarkers.xlsx');
inputfilelist = rampeventmarkerinput.textdata.Sheet1(2:end,1);

% Catch mismatches between event markers and current files of interest
if (isequal(inputfilelist,filelist)==0)
    warning('Mismatch between input and current selected files of interest')
    break
end

% Collect ramp start data
inputrampstarteventmarkers = rampeventmarkerinput.data.Sheet1(1:end,1);


%% Collect data from all files of interest 
disp('Binning data..')
% Initialize a cell array of interest +1 for study label
postrampdatablock = cell(size(idxFilesOfInterest,1),numData+1);
prerampdatablock  = cell(size(idxFilesOfInterest,1),numData+1);

% 10-second bins pre/post ramp start %
for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest))
    % Loop over all files of interest (within filetype) in the directory
    try
        % Select variable column of interest, transpose %
        % Import data
        importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
        data = importedFile.data(:,col); % col references ignore cnt/dateTime
        time = importedFile.data(:,1); % fixed % column 1
        events = importedFile.data(:,2); % fixed @ column 2

        % Locate beginning of ramp and bin from ramp as the central
        % point
        % Use input marker data
        idxrampstart = find(events == inputrampstarteventmarkers(iFilesOfInterest));

        postrampstartdata = data(idxrampstart:end);
        postrampstarttime = time(idxrampstart:end);
        prerampstartdata  = data(1:idxrampstart);
        prerampstarttime  = time(1:idxrampstart);

        % Bin post ramp start data
        % UNEQUALSIZEDBINS Custom function to make bins over an
        % interval where:
        % [ binMeans ] = unequalsizedbins( interval,data,time )
        postrampstartBinMeans = unequalsizedbins(...
            bininterval,postrampstartdata,postrampstarttime);

        % Flip pre ramp start data and bin
        prerampstartdata_flipped = fliplr(prerampstartdata);
        prerampstartBinMeans = unequalsizedbins(...
            bininterval,prerampstartdata_flipped,prerampstarttime);


    catch DataOrEventErr
        warning('Missing data/Event - %s',fileType(iFilesOfInterest).name)
        break
    end

    % Enter post ramp data into cell array shifted 1 col for study label
    postrampdatablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    postrampdatablock(iFilesOfInterest,...
        2:(size(postrampstartBinMeans,1)+1)) = ...
    transpose(num2cell(postrampstartBinMeans));

    % Enter pre ramp data into cell array shifted 1 col for study label
    prerampdatablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    prerampdatablock(iFilesOfInterest,...
        2:(size(prerampstartBinMeans,1)+1)) = ...
        transpose(num2cell(prerampstartBinMeans));

    if (size(postrampdatablock,1) == 0) || (size(prerampdatablock,1) == 0)
    % Stop script if pre and post ramp start data blocks are not the same size
        disp(iFilesOfInterest)
        break
    end
end % end file loop


% Locate maximum study length of time-axis by locating longest testing session % 

% Post ramp start data block
maxlengthpostrampdatablock = findMaxTestLength(postrampdatablock)-1; % remove label
% Pre ramp start data block
maxlengthprerampdatablock = findMaxTestLength(prerampdatablock)-1; % remove label


% 'Right justified' pre ramp start data block %
rightjustifiedprerampdatablock = prerampdatablock;
for iRow = 1:size(prerampdatablock,1)
    % Circularly shift row to match longest study
    currentRowLength = find(...
        ~cellfun('isempty',prerampdatablock(iRow,2:end)),1,'last');
    rightjustifiedprerampdatablock(iRow,2:end) = circshift(...
        rightjustifiedprerampdatablock(iRow,2:end),...
        [0 (maxlengthprerampdatablock-currentRowLength)]);
end

% Combined data block with time axis scale % 
    % '-1' for pre-ramp refers to removing the ramp-start bin from
    % consideration
    % Combination includes: 
    % 1) 'Right justified' pre ramp start data blcok
    % 2) post ramp start data block
   
% Generate time axis % 

% Generate pre ramp start time axis
prerampstarttimeaxis = ...
    -bininterval*(maxlengthprerampdatablock-1):...
    bininterval:...
    -bininterval;  

% Generate post ramp start time axis
postrampstarttimeaxis = ...
    0:bininterval:bininterval*maxlengthpostrampdatablock;

% Combine pre/post ramp time axes
currentcombinedtimeaxis = horzcat(...
    prerampstarttimeaxis,postrampstarttimeaxis);

% Combine pre/post data %

% Combine pre/post ramp data blocks
currentprocesseddata = horzcat(...
    rightjustifiedprerampdatablock(:,2:end),...
    postrampdatablock(:,2:end));
% Remove empty columns
currentprocesseddata(...
    :,all(cellfun(@isempty,currentprocesseddata),1)) = [];


% Combine data and time axis
combineddatablock = cell(...
    size(currentprocesseddata,1)+1,...
    size(currentprocesseddata,2)+1);
combineddatablock(1,1) = {'Time(sec)'};
combineddatablock(2:end,1) = prerampdatablock(:,1);
combineddatablock(2:end,2:end) = currentprocesseddata;
combineddatablock(1,2:end) = num2cell(currentcombinedtimeaxis);
    
        
% 3 minute -10 sec bins %
% Each bin is -10 seconds from time point of interest
% Time points of interest are 0 (ramp start), and every 180 sec after

% Initialize a cell array of interest +1 for study label
threeminpostrampdatablock = cell(size(idxFilesOfInterest,1),numData+1);

for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest))
% Loop over all files of interest (within filetype) in the directory

    try % Select variable column of interest, transpose %
        % Import data
        importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
        data = importedFile.data(:,col); % col references ignore cnt/dateTime
        time = importedFile.data(:,1); % fixed % column 1
        events = importedFile.data(:,2); % fixed @ column 2

        % Locate beginning of ramp and bin from ramp as the central point
        % Use input marker data
        idxrampstart = find(events == inputrampstarteventmarkers(iFilesOfInterest));
        
        % Locate three minute intervals for individual session
        currentadjustedtime = time - time(idxrampstart);
        currentthreeminlocs = 0:180:currentadjustedtime(end);

        % Initialize method variables
        last10secBinMeans = NaN(length(currentthreeminlocs),1);

        for ithreeminloc = 1:numel(currentthreeminlocs);
        % For each three minute time-point

            %Initialize/reset flags
            flagForBin = false(length(currentadjustedtime),1);

            % Flag data that fits into current interval (-10 seconds)
            allIdx = 1:numel(currentadjustedtime);
            idxBin = allIdx(...
                currentadjustedtime >= (currentthreeminlocs(ithreeminloc)-10) &...
                currentadjustedtime <= currentthreeminlocs(ithreeminloc));
            flagForBin(idxBin) = true;

            % Get bin mean
            last10secBinMeans(ithreeminloc,1) = mean(data(flagForBin));
        end

        
    catch DataOrEventErr
        warning('Missing data/Event - %s',fileType(iFilesOfInterest).name)
        break
    end
    
    % Enter post ramp data into cell array shifted 1 col for study label
    threeminpostrampdatablock(iFilesOfInterest,1) = cellstr(...
        fileType(iFilesOfInterest).name);
    threeminpostrampdatablock(iFilesOfInterest,...
        2:(size(last10secBinMeans,1)+1)) = ...
    transpose(num2cell(last10secBinMeans));

end

% Remove empty columns
threeminpostrampdatablock(...
    :,all(cellfun(@isempty,threeminpostrampdatablock),1)) = [];

% Find max study length of three min time points post ramp start data block
maxlengththreemindatablock = findMaxTestLength(threeminpostrampdatablock)-1; % remove label

% Generate time axis scale
threemindatablocktime = 0:180:180*maxlengththreemindatablock-1;

% Combine data block with scale
combinedthreemindatablock = cell(...
    size(threeminpostrampdatablock,1)+1,...
    (maxlengththreemindatablock+1));

combinedthreemindatablock(1,1) = {'Time(sec)'};
combinedthreemindatablock(2:end,:) = threeminpostrampdatablock;
combinedthreemindatablock(1,2:end) = num2cell(threemindatablocktime);



%% Output figures for visual confirmation
disp('Outputting figures..')
% Get current directory if not already present
if exist('currentdir','var') == 0
    currentdir = pwd; 
end

% Output unbinned data %

% Create new unbinned figures folder if not already present
unbinneddataplotsfolder = 'Plots - Raw data';
if exist(...
        [currentdir '\' unbinneddataplotsfolder],...
        'dir') == 0
    mkdir(unbinneddataplotsfolder)
end

% Create a new variables subfolder if not already present
if exist(...
        [currentdir '\' unbinneddataplotsfolder '\' label],...
        'dir') == 0
    cd([currentdir '\' unbinneddataplotsfolder])
    mkdir(label)
    cd(currentdir)
end


if exist('DataOrEventErr','var') == 0
% If there are no previous data aquisition errors, output raw data figs
    for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest))
        % Import data
        importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
        data = importedFile.data(:,col); % col references ignore cnt/dateTime
        time = importedFile.data(:,1); % fixed % column 1
        events = importedFile.data(:,2); % fixed @ column 2

        currentfilename = fileType(iFilesOfInterest).name;

        % Make figure
        figure;
        hold on
        set(gcf,'Visible','off', 'Color', 'w');
        [hAx,~,~] = plotyy(...
            time,data,...
            time,events);
        title(sprintf('%s',strrep(currentfilename,'_',' ')))
        xlabel('Time (seconds)');
        ylabel(hAx(1),strrep(label,'_',' '));
        ylabel(hAx(2),'Marker');
        hold off

        % Save into new folder
        cd([currentdir '\' unbinneddataplotsfolder '\' label])
        export_fig(sprintf('%s',currentfilename),'-png','-m2');
        cd(currentdir)
    end
end


% Output binned data %

% Create new binned figures folder if not already present
binneddataplotsfolder = 'Plots - Binned data';
if exist(...
        [currentdir '\' binneddataplotsfolder],...
        'dir') == 0
    mkdir(binneddataplotsfolder)
end

% Create a new variables subfolder if not already present
if exist(...
        [currentdir '\' binneddataplotsfolder '\' label],...
        'dir') == 0
    cd([currentdir '\' binneddataplotsfolder])
    mkdir(label)
    cd(currentdir)
end

% Check if bin means are equally sized and a label is present
if size(postrampdatablock,1) == size(prerampdatablock,1) &&...
        exist('label','var') == 1
    % Output preliminary figures in data block
    for iProcessedFile = 1:size(postrampdatablock,1)
        
        % Get length of study (not including label)%
        
        % Pre ramp start
        currentprerowlength = find(...
            ~cellfun('isempty',...
            prerampdatablock(iProcessedFile,:)),1,'last')-1;
        % Post ramp start
        currentpostrowlength = find(...
            ~cellfun('isempty',...
            postrampdatablock(iProcessedFile,:)),1,'last')-1;
        
        % Generate axis % 
        
        % Generate pre ramp start time axis
        prerampstarttimeaxis = ...
            -bininterval*(currentprerowlength-1):...
            bininterval:...
            -bininterval;  
        
        % Generate post ramp start time axis
        postrampstarttimeaxis = ...
            0:bininterval:bininterval*currentpostrowlength;
        
        % Combine pre/post ramp time axes
        currentcombinedtimeaxis = horzcat(...
            prerampstarttimeaxis,postrampstarttimeaxis);
        
        % Combine pre/post data %
        
        % Combine pre/post ramp data blocks
        currentprocesseddata = cell2mat(horzcat(...
            prerampdatablock(iProcessedFile,2:end-1),...
            postrampdatablock(iProcessedFile,2:end)));
            % Select one data point less in prerampdatablock
            % to remove overlapping 0 second time point
        
        % Grab label from first cell
        currentfilename = postrampdatablock{iProcessedFile,1};
        
        % Make figure %
        figure;
        hold on
        set(gcf,'Visible','off', 'Color', 'w');
        plot(...
            currentcombinedtimeaxis,currentprocesseddata);
        title(sprintf('%s',strrep(currentfilename,'_',' ')))
        xlabel('Time (seconds)');
        ylabel(strrep(label,'_',' '));
        hold off

        % Save into new folder
        cd([currentdir '\' binneddataplotsfolder '\' label])
        export_fig(sprintf('%s',currentfilename),'-png','-m2');
        cd(currentdir)
    end
end

%% Output spreadsheets
disp('Outputting spreadsheets..')
% Data - Binned Summary excel workbook format %

% Get current directory if not already present
if exist('currentdir','var') == 0
    currentdir = pwd; 
end

% Create new binned figures folder if not already present
summaryworkbookfolder = 'Data - Binned Summary';
if exist(...
        [currentdir '\' summaryworkbookfolder],...
        'dir') == 0
    mkdir(summaryworkbookfolder)
end

% Write cell array to an excel workbook file 

% CD to Summary workbook folder
cd([currentdir '\' summaryworkbookfolder])

% Combined summary workbook
outputworkbookfilename = [outputFileName '.xlsx'];
xlswrite(outputworkbookfilename,combineddatablock,1,'A1');
xlswrite(outputworkbookfilename,prerampdatablock,2,'A1');
xlswrite(outputworkbookfilename,postrampdatablock,3,'A1');
xlswrite(outputworkbookfilename,combinedthreemindatablock,4,'A1');
xlswrite(outputworkbookfilename,inputmetadata,5,'A1');
e = actxserver('Excel.Application'); 
    ewb = e.Workbooks.Open([pwd '\' outputworkbookfilename]);
    ewb.Worksheets.Item(1).Name = 'For copy & paste';
    ewb.Worksheets.Item(2).Name = 'Pre-ramp-start data';
    ewb.Worksheets.Item(3).Name = 'Post-ramp-start data';
    ewb.Worksheets.Item(4).Name = 'Three Min Interval';
    ewb.Worksheets.Item(5).Name = 'Metadata';
    ewb.Save
    ewb.Close(false);
    e.Quit

% Switch to working directory
cd(currentdir)


% Output Data - Unbinned CSV format with ramp start adjusted time  %

if nirs2rampstartcsv % manually set to to true or false in script input
    disp('Outputting unbinned ramp adjusted time CSVs..')
    % Get current directory if not already present
    if exist('currentdir','var') == 0 %#ok<UNRCH>
        currentdir = pwd; 
    end

    % Create new binned figures folder if not already present
    unbinnedrampadjtimefolder = 'Data - unbinned with ramp adjusted time';
    if exist(...
            [currentdir '\' unbinnedrampadjtimefolder],...
            'dir') == 0
        mkdir(unbinnedrampadjtimefolder)
    end

    % Process will take ~1 min for each file
    for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest)) 
        pocketnirslog = importNIRSdata(fileType(iFilesOfInterest).name);

        % Locate ramp start using selected event marker.
        idxrampstart = pocketnirslog.Event==inputrampstarteventmarkers(iFilesOfInterest);

        % Add in adjusted time column
        pocketnirslog.RampStartAdjTime = pocketnirslog.ElapsedTime - pocketnirslog.ElapsedTime(idxrampstart);

        % Export to csv file in new folder
        filename = [strrep(fileType(iFilesOfInterest).name,'.PNI',''),...
            label, '.csv'];
        cd([currentdir '\' unbinnedrampadjtimefolder])
        export(pocketnirslog,'file',filename,'Delimiter',',')
        cd(currentdir)
    end
end

% Finished message
 disp('Done!')