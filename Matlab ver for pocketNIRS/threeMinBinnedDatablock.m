function [ combinedthreemindatablock, DataOrEventErr ] = ...
    threeMinBinnedDatablock(...
        fileType,...
        idxFilesOfInterest,...
        col,...
        numData,...
        inputrampstarteventmarkers,...
        inputrampendeventmarkers)
%% 3 minute -10 sec bins %
% Repeat binning procedure with 3-minute intervals. Each bin starts at
% '-binning interval' (e.g. -10 seconds) from time point of interest. Time
% points of interest start at 0 (ramp start), and every 180 sec after if
% data is available. 
%
% Inputs: 
%   1. file list, saved dir() call in working directory
%   2. files of interest, boolean array denoting files of interest within
%       the file list
%   3. numData, max # of data points per study for variable of interest
%   4. event markers denoting start and finish of exercise challenge,
%       numeric array
%
% Outputs:
%   1. combinedthreemindatablock, cell
%       format: a table with testing session data seperated by rows, 
%       with column data for xlsx output
%

%% Check for correct inputs prior to starting analysis
if nargin ~= 6
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

 
%% Start function
% Initialize a cell array of interest +1 for study label
threeminpostrampdatablock = cell(size(idxFilesOfInterest,1),numData+1);

for iFilesOfInterest = 1:length(fileType(idxFilesOfInterest))
% Loop over all files of interest (within filetype) in the directory

    try % Select variable column of interest, transpose %
        % Import data via function
        importedFile = importdata(fileType(iFilesOfInterest).name, ',',4);
        data = importedFile.data(:,col); % col references ignore cnt/dateTime
        time = importedFile.data(:,1); % fixed % column 1
        events = importedFile.data(:,2); % fixed @ column 2

        % Locate beginning of ramp and bin from ramp as the central point
        % Use input marker data
        idxrampstart = find(events == inputrampstarteventmarkers(iFilesOfInterest));
        idxrampend   = find(events == inputrampendeventmarkers(iFilesOfInterest));
        
        % Locate three minute intervals for individual session with ramp
        % only
        currentadjustedtime = time(idxrampstart:idxrampend);
        currentadjustedtime = currentadjustedtime - time(idxrampstart);
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
    
    % Clean up file name via function 'getsubjectID'
    % Input: file name, string
    % Output: subject ID, string
    currentFileName = fileType(iFilesOfInterest).name;
    subjectIdentifier = getsubjectID(currentFileName);
    
    % Enter post ramp data into cell array shifted 1 col for study label
    threeminpostrampdatablock(iFilesOfInterest,1) = cellstr(...
        subjectIdentifier);
    threeminpostrampdatablock(iFilesOfInterest,...
        2:(size(last10secBinMeans,1)+1)) = ...
    transpose(num2cell(last10secBinMeans));

end

% Remove empty columns
threeminpostrampdatablock(...
    :,all(cellfun(@isempty,threeminpostrampdatablock),1)) = [];

% Find max study length of three min time points
% using post ramp start data block and findMaxTestLength function
maxlengththreemindatablock = findMaxTestLength(threeminpostrampdatablock)-1; % remove label

% Generate time axis scale
threemindatablocktime = 0:180:180*maxlengththreemindatablock-1;

% Combine data block with scale
combinedthreemindatablock = cell(...
    size(threeminpostrampdatablock,1)+1,...
    (maxlengththreemindatablock+1));

combinedthreemindatablock(1,1) = {'SubjectID'};
combinedthreemindatablock(2:end,:) = threeminpostrampdatablock;
combinedthreemindatablock(1,2:end) = num2cell(threemindatablocktime);


end

