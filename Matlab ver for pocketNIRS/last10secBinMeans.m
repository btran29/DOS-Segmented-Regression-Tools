function [ last10secBinMeans ] = last10secBinMeans( interval,data,time )
%UNEQUALSIZEDBINS Bins data over a given interval given time and data
%   Data point count in each bin is determined by the given interval
%   Interval is in the units of time as specified by the time axis

% Define bin edges
binEdges = 0:interval:(time(end)+interval); % add an extra step

% Initialize method variables
last10secBinMeans = NaN(length(binEdges),1);

% Loop through each bin
for i = 1:length(binEdges)-1;
    
    %Initialize/reset flags
    flagForBin = false(length(time),1);

    % Flag data that fits into current bin
    allIdx = 1:numel(time);
    idx = allIdx(time >= binEdges(i-1) & time <= binEdges(i));
    flagForBin(idx) = true;

    % Assign data to bin and get mean
    last10secBinMeans(i,1) = mean(data(flagForBin));
end

% Remove NaNs
last10secBinMeans = binMeans(~isnan(binMeans));
end

