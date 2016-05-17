function [ postrampdatablock,...
           prerampdatablock,...
           combineddatablock,...
           DataOrEventErr] = tenSecBinnedDatablock( ...
                                fileType,...
                                idxFilesOfInterest,...
                                col,...
                                numData,...
                                inputrampstarteventmarkers,...
                                inputrampendeventmarkers,...
                                bininterval)
%% 10-second bins pre/post ramp start %
% Bin data by binning interval, create a table. Sort individiual files in
% to rows on the table. Output the table, in 3 formats with data before the 
% start of the exercise challenge (warmup) and throughout the exercise
% challenge. 'Right justify' the output data for the warmup and 'left
% justify' the output data for the exercise challenge. 
%   1. file list, saved dir() call in working directory
%   2. files of interest, boolean array 
%       denotes files of interest within the file list
%   3. col, double
%       which column of data from raw pocketNIRS data to bin
%   4. numData, double
%       max # of data points per study for variable of interest
%   5. event markers denoting start and finish of exercise challenge,
%       numeric array
%   6. bininterval, double
%       interval over which to bin time axis
%
% Outputs:
%   1. postrampdatablock, cell
%       format: a table with testing session data seperated by rows, 
%       for xlsx output
%   2. prerampdatablock, cell
%       format: a table with testing session data seperated by rows, 
%       for xlsx output
%   3. combineddatablock, cell
%       format: a table with testing session data seperated by rows, 
%       with column data for xlsx output
%   4. DataOrEventErr, error
%       in case there either missing imported data or event marker data

%% Check for correct inputs prior to starting analysis
if nargin ~= 7
    warning('Missing inputs')
    return
end
if isstruct(fileType) == 0
    warning('Missing/invalid input dir() call, fileType')
    return
end
if islogical(idxFilesOfInterest) == 0 
    warning('Missing/invalid files of interest boolean index,idxFilesOfInterest')
end
if isnumeric(col) == 0
    warning('Missing/invalid column of data to bin');
    return
end
if isnumeric(numData) == 0
    warning('Missing/invalid maximum number of data points, numData')
    return
end
if isnumeric(inputrampstarteventmarkers) == 0 || isnumeric(inputrampendeventmarkers) == 0
    warning('Missing/invalid array of input markers')
    return
end
if isnumeric(bininterval) == 0
    warning('Missing/invalid binning interval, bininterval')
    return
end

%% Start function
% Initialize a cell array of interest +1 for file label
postrampdatablock = cell(size(idxFilesOfInterest,1),numData+1);
prerampdatablock  = cell(size(idxFilesOfInterest,1),numData+1);

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
        idxrampend   = find(events == inputrampendeventmarkers(iFilesOfInterest));

        postrampstartdata = data(idxrampstart:idxrampend);
        postrampstarttime = time(idxrampstart:idxrampend);
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
     
    % Clean up file name via function 'getsubjectID'
    % Input: file name, string
    % Output: subject ID, string
    currentFileName = fileType(iFilesOfInterest).name;
    subjectIdentifier = getsubjectID(currentFileName);
   
    % Enter post ramp data into cell array shifted 1 col for study label
    postrampdatablock(iFilesOfInterest,1) = cellstr(...
        subjectIdentifier);
    postrampdatablock(iFilesOfInterest,...
        2:(size(postrampstartBinMeans,1)+1)) = ...
    transpose(num2cell(postrampstartBinMeans));

    % Enter pre ramp data into cell array shifted 1 col for study label
    prerampdatablock(iFilesOfInterest,1) = cellstr(...
        subjectIdentifier);
    prerampdatablock(iFilesOfInterest,...
        2:(size(prerampstartBinMeans,1)+1)) = ...
        transpose(num2cell(prerampstartBinMeans));

    if (size(postrampdatablock,1) == 0) || (size(prerampdatablock,1) == 0)
    % Stop script if pre and post ramp start data blocks are not the same size
        disp(iFilesOfInterest)
        warning('either pre or post ramp start data blocks cannot be created')
        break
    end
end % end file loop


% Locate maximum study length of time-axis by locating longest testing 
% session in order to generate a time axis of the appropriate length and
% 'right-justify' a block of data

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
end

