function [ peakVO2, idxPeakVO2 ] = maxwindow(time,var,windowlength)
%MAXWINDOW Method to find peakVO2
% Take a sliding window across a time axis and a continuous data axis of
% the same length, mean each window, and locate the maximum mean.
% time = time axis
% var = data axis
% windowlength = length of window, based on input time axis units

%% Windowing Logic
% Initialize windowmean collection variable
windowmean = zeros(1,length(time)); 

% Sliding window
windowhalflength = windowlength*0.5;
for iRow = 1:length(time)
    % Ensure all windows contain windowlength of data
    if time(iRow) >= windowhalflength && ...
            time(iRow) <= (max(time)-windowhalflength);
        % Grab upper and lower window bounds
        lowerValue = time(iRow) - windowhalflength;
        upperValue = time(iRow) + windowhalflength;
        [~,idxLower] = min(abs(time-lowerValue));
        [~,idxUpper] = min(abs(time-upperValue));
        % Mean for variable of interest
        windowmean(iRow) = mean(var(idxLower:idxUpper)); 
    else
        windowmean(iRow) = NaN; 
    end
end

%% Output
% Get peak value by taking the highest mean
[peakVO2,idxPeakVO2] = max(windowmean);
end

