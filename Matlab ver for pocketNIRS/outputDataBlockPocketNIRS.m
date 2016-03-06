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
label = 'CH1_delta_oxyHb_(au)';

% Column of data to select
col = 7; 
% Channel 1
    % column 7 = CH1_delta_oxyHb_(au)
    % column 8 = CH1_delta_deoxyHb_(au)	
    % column 9 = CH1_delta_totalHb_(au)
% Channel 2
    % column 16 = CH2_delta_oxyHb_(au)
    % column 17 = CH2_delta_deoxyHb_(au)	
    % column 18 = CH2_delta_totalHb_(au)    


% Binning interval
bininterval = 10;
    
% Metadata list
inputmetadata = {
    'Keyword Used','Workbook Label','Column Used',...
    'Bin Interval','Date Generated';...
    keyword{1},label,col,bininterval,datestr(now,0)};

% Filename of output xslx
outputFileName = strcat('',keyword{1},'_',label);

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
inputrampstarts = rampeventmarkerinput.data.Sheet1(1:end,1);


%% Collect data from all files of interest 

% Initialize a cell array of interest +1 for study label
postrampdatablock = cell(size(idxFilesOfInterest,1),numData+1);
prerampdatablock  = cell(size(idxFilesOfInterest,1),numData+1);

% Loop over all files of interest (within filetype) in the directory
for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest))
    % Select variable column of interest, transpose
    try
        % Import data
        importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
        data = importedFile.data(:,col); % col references ignore cnt/dateTime
        time = importedFile.data(:,1); % fixed % column 1
        events = importedFile.data(:,2); % fixed @ column 2

        % Locate beginning of ramp and bin from ramp as the central
        % point
        % Use input marker data
        idxrampstart = find(events == inputrampstarts(iFilesOfInterest));

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

        % Generate pre ramp start time axis
        prerampstarttimeaxis = ...
            -bininterval*length(prerampstartBinMeans):...
            bininterval:...
            bininterval*length(postrampstartBinMeans);    

    catch DataOrEventErr
        warning('Missing data/Event - %s',fileType(iFilesOfInterest).name)
        break
    end

% Enter post ramp data into cell array shifted 1 col for study label
postrampdatablock(iFilesOfInterest,1) = cellstr(...
    fileType(iFilesOfInterest).name);
postrampdatablock(iFilesOfInterest,2:(size(postrampstartBinMeans,1)+1)) = ...
    transpose(num2cell(postrampstartBinMeans));

% Enter pre ramp data into cell array shifted 1 col for study label
prerampdatablock(iFilesOfInterest,1) = cellstr(...
    fileType(iFilesOfInterest).name);
prerampdatablock(iFilesOfInterest,2:(size(prerampstartBinMeans,1)+1)) = ...
    transpose(num2cell(prerampstartBinMeans));


end % end file loop

% Clean up cell array by removing empty rows
postrampdatablock(all(cellfun(@isempty,postrampdatablock),2), : ) = [];
prerampdatablock(all(cellfun(@isempty,prerampdatablock),2), : ) = [];

if (size(postrampdatablock,1) == 0) || (size(prerampdatablock,1) == 0)
    disp(iFilesOfInterest)
    break
end
%% Output to excel workbook

% Write cell array to an excel workbook file 

% Post ramp start data
postrampstartoutputfilename = [outputFileName,'_rampstart','.xlsx'];
xlswrite(postrampstartoutputfilename,postrampdatablock,1,'A1');
xlswrite(postrampstartoutputfilename,inputmetadata,2,'A1');

% Pre ramp start data
prerampstatoutputfilename = [outputFileName,'_prerampstart','.xlsx'];
xlswrite(prerampstatoutputfilename,prerampdatablock,1,'A1');
xlswrite(prerampstatoutputfilename,inputmetadata,2,'A1');

% Label workbook sheets
outputfilename = {postrampstartoutputfilename,prerampstatoutputfilename};
for ioutputfilename = 1:2
%     currentoutputfilename = outputfilename(ioutputfilename);
%  
%     e = actxserver('Excel.Application'); 
%     ewb = e.Workbooks.Open([pwd '\' currentoutputfilename]);
%     ewb.Worksheets.Item(1).Name = 'Data';
%     ewb.Worksheets.Item(2).Name = 'Metadata';
%     ewb.Save
%     ewb.Close(false);
%     e.Quit
end
 disp('Done!')