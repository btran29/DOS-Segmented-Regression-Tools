% Ver 4-22-16 Brian
%% Output transposed block of a column of data from studies w/ keywords
% This script selects a column of data from all studies in a 
% working directory, then outputs it all in a single copy-
% paste-able block in a workbook named after the first search term.
% 
%% Workflow
%
% Set keyword to a study phase: e.g. keyword = {'Baseline'}. For
% multiple keywords, make it a list, e.g. keyword = {'Baseline',
% 'Brain', 'AnSa'}. Keywords can be anything in the file name,
% as long as it is separated on both sides by the delimiter,
% e.g. an empty space ' ' or an underscore '_'.
% 
% Set label for the output (e.g. keywords, variable of interest in the 
% selected data). It must not have spaces and work as a windows folder 
% name. The script will output folders with the same label to make
% individual files easier to find.
%
% Assuming that data across tests are consistent, select a column that
% would correspond to the variable of interest, as labeled.
%
% On the first run, the script will output a workbook. This workbook will
% point the script to where the exercise challenge starts, as well as the
% the time point at which the participant has reached 50% of their peakVO2.
% The default marker values should be copied and pasted into the first
% sheet of this workbook. The time for 50% peakVO2 should be obtained from
% metabolic cart data processing for each subject, then input in to the
% *first* sheet of this workbook as well. The script can then be run once.
%
% The first output may look off; this is likely due to human error in
% placing event markers. Look at the raw output of the script for the tests
% that look incorrect and make adjustments to the selected markers as
% necessary in the *first* sheet of event marker workbook. The second sheet
% will be overwritten with default values every time the script is run to
% show the format of the tables to be used as input.
%
% If you would like output more than one variable at a time, set up the
% labels and columns as cell arrays:
%       labels = {'CH1_delta_oxyHb_(au),'CH1_delta_deoxyHb_(au)'};
%       cols = {7,8};
%
% The first label should correspond to the first selected column, and so
% on.
%
%
%% User input
% 
% % Reset environment
% clear all

% Use some string to uniquely identify files of interest. Can be file 
% extensions or key words (e.g. '*.xls' or '*.csv')
fileIdentifier = '*.PNI';

% If you would like to further narrow file selection you can use an 
% additional key word (e.g. study phase, subject IDs, etc.)
keyword = {'pocket_nirs'};

% Label for the output (e.g. keywords, variable of interest in the column 
% of data to select). Must not have spaces, and work as a windows folder 
% name (script will output folders with the same label to stratify output).
labels = {'CH1_delta_oxyHb_(au)',...
    'CH1_delta_deoxyHb_(au)',...
    'CH1_delta_totalHb_(au)',...
    'CH2_delta_oxyHb_(au)',...
    'CH2_delta_deoxyHb_(au)',...
    'CH2_delta_totalHb_(au)'};

% Assuming data is in a consistent format, this list corresponds to the 
% column of data to select
cols = [7,8,9,16,17,18];

% An example with only one data set
% labels = 'CH2_delta_deoxyHb';
% cols = 17; 

% For reference
% Channel 1
    % column 7 = CH1_delta_oxyHb_(au)
    % column 8 = CH1_delta_deoxyHb_(au)	
    % column 9 = CH1_delta_totalHb_(au)
% Channel 2
    % column 16 = CH2_delta_oxyHb_(au)
    % column 17 = CH2_delta_deoxyHb_(au)	
    % column 18 = CH2_delta_totalHb_(au)    

% TODO: move the looped code to a function

%% Loop across labels and columns
for iCurrentdatatype = 1:length(labels);

% Select current data type
label = labels{iCurrentdatatype};
col = cols(iCurrentdatatype);

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
numData = 500; % Some arbitrarily large value; 
%     TODO: replace 500 with a relevant dynamically generated variable
%       can introduce an error if the length of any given study is larger
%       than 500*binning interval.


%% Identify files of interest
% Generate file list
fileType = dir(fileIdentifier);

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
markerlist = cell(length(filelist),2);
markerlist(:,1) = {2}; % beginning ramp by default is 2
markerlist(:,2) = {3}; % end ramp by default is 3

% Generate default 50% peak VO2 array
markerlist(:,3) = {0}; % default null value

% Combine arrays
inputlistarray = horzcat(filelist,markerlist);

% Generate headers
headers = {'filename','exeStart','exeEnd','timehalfpeakVO2'};

% Output to an easily editable workbook + notify in console
inputfilename = 'RampEventMarkers.xlsx';
xlswrite(inputfilename,headers,2,'A1');
xlswrite(inputfilename,inputlistarray,2,'A2');
fprintf('\nGenerated input workbook in current directory.')
fprintf('\nNOTE: New data is in the 2nd sheet to prevent overwriting.\n')


%% Require user input prior to continuing
if iCurrentdatatype == 1
prompt = '\nHave the markers & time to 50% peakVO2 been located and entered into the input\n workbook? Press enter to continue. \n';
x = input(prompt);
end

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
inputrampendeventmarkers = rampeventmarkerinput.data.Sheet1(1:end,2);
inputhalfpeakVO2time = rampeventmarkerinput.data.Sheet1(1:end,3);


%% Collect data from all files of interest 
disp('Binning data..')


%% 10-second bins pre/post ramp start %
[postrampdatablock,...
 prerampdatablock,...
 combineddatablock,...
 DataOrEventErr_TenSec] = tenSecBinnedDatablock(...
                                fileType,...
                                idxFilesOfInterest,...
                                col,...
                                numData,...
                                inputrampstarteventmarkers,...
                                inputrampendeventmarkers,...
                                bininterval);

        
%% 3 minute -10 sec bins %
[ combinedthreemindatablock, DataOrEventErr ] = threeMinBinnedDatablock(...
                                            fileType,...
                                            idxFilesOfInterest,...
                                            numData,...
                                            inputrampstarteventmarkers,...
                                            inputrampendeventmarkers);

                                        
%% Generate values highlighting the trajectory of the variable of interest %
numberoftests = size(fileType(idxFilesOfInterest),1);
[halfmaxdatablock , peakVO2Err] = halfmaxdatablock( ...
                                    numberoftests, ...
                                    postrampdatablock, ...
                                    inputhalfpeakVO2time );
                                
                                
%% Output figures for visual confirmation
% Generate unique directories to output figures of both raw and binned
% data.

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
% If there are no previous data aquisition errors with raw data, output the
% raw data figures
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
        xlabel('Time (seconds) relative to exercise challenge');
        ylabel(strrep(label,'_',' '));
        hold off

        % Save into new folder
        cd([currentdir '\' binneddataplotsfolder '\' label])
        export_fig(sprintf('%s',currentfilename),'-png','-m2');
        cd(currentdir)
    end
end

%% Workbook post-processing
combineddatablock = contigIDsort(combineddatablock);
prerampdatablock = contigIDsort(prerampdatablock);
postrampdatablock = contigIDsort(postrampdatablock);
combinedthreemindatablock = contigIDsort(combinedthreemindatablock);
halfmaxdatablock = contigIDsort(halfmaxdatablock);

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
xlswrite(outputworkbookfilename, halfmaxdatablock,5,'A1');
xlswrite(outputworkbookfilename,inputmetadata,6,'A1');
e = actxserver('Excel.Application'); 
    ewb = e.Workbooks.Open([pwd '\' outputworkbookfilename]);
    ewb.Worksheets.Item(1).Name = 'For copy & paste';
    ewb.Worksheets.Item(2).Name = 'Pre-ramp-start data';
    ewb.Worksheets.Item(3).Name = 'Post-ramp-start data';
    ewb.Worksheets.Item(4).Name = 'Three Min Interval';
    ewb.Worksheets.Item(5).Name = '0-50% peakVO2 data';
    ewb.Worksheets.Item(6).Name = 'Metadata';
    ewb.Save
    ewb.Close(false);
    e.Quit

% Switch to working directory
cd(currentdir)


% Output Data - Unbinned CSV format with ramp start adjusted time  %
% TODO: FIX TO WORK WITHOUT USE OF DATASET DATA TYPE

% if nirs2rampstartcsv % manually set to to true or false in script input
%     disp('Outputting unbinned ramp adjusted time CSVs..')
%     % Get current directory if not already present
%     if exist('currentdir','var') == 0 %#ok<UNRCH>
%         currentdir = pwd; 
%     end
% 
%     % Create new binned figures folder if not already present
%     unbinnedrampadjtimefolder = 'Data - unbinned with ramp adjusted time';
%     if exist(...
%             [currentdir '\' unbinnedrampadjtimefolder],...
%             'dir') == 0
%         mkdir(unbinnedrampadjtimefolder)
%     end
% 
%     % Process will take ~1 min for each file
%     % Requires dataset data type support
%     for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest)) 
%         pocketnirslog = importNIRSdata(fileType(iFilesOfInterest).name);
%         pocketnirs
% 
%         % Locate ramp start using selected event marker.
%         for iRow = 1:length(pocketnirslog.Event)
%             if isequal(pocketnirslog.Event,[''' inputrampstarteventmarkers(iFilesOfInterest)])
%                 idxrampstart = iRow
%             end
%         end
%         % Add in adjusted time column
%         pocketnirslog.RampStartAdjTime = pocketnirslog.ElapsedTime - pocketnirslog.ElapsedTime(idxrampstart);
% 
%         % Export to csv file in new folder
%         filename = [strrep(fileType(iFilesOfInterest).name,'.PNI',''),...
%             label, '.csv'];
%         cd([currentdir '\' unbinnedrampadjtimefolder])
%         export(pocketnirslog,'file',filename,'Delimiter',',')
%         cd(currentdir)
%     end
% end

% Finished message
 disp('Done!')
end