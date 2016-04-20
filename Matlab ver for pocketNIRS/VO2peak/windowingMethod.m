%% Window data to remove noise
%% Input
% Specify a time axis
time = TimeSec_exe;

% Specify a variable
var = exe_VO2;

% Specify a window length (based on an input time axis units)
windowlength = 20; 

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
peakVO2(iFile) = max(windowmean);