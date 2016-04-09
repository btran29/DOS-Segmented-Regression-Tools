% Create input variables
sheetNames = {'1010',...
                '1005',...
                '1014',...
                '1020',...
                '1001',...
                '1003',...
                '1002',...
                '1009',...
                '1013',...
                '1006',...
                '1007',...
                '1011',...
                '1004',...
                '1012',...
                '1015',...
                '1016',...
                '1017',...
                '1018',...
                '1019',...
                '1021',...
                '1022',...
                '1023',...
                '1025',...
                '1024',...
                '1008'};

endRows = [529
            463
            859
            463
            463
            463
            463
            529
            463
            463
            463
            397
            463
            595
            595
            331
            463
            529
            397
            463
            397
            397
            463
            529
            463];

% Create collection variables
peakVO2 = zeros(1,25);
plateau = cell(1,25);
peakRQ  = zeros(1,25);
peakHR  = zeros(1,25);

for iFile = 1:25        
    % Import
    workbookFile = 'PS work rate calculations.xlsx';
    sheetName = sheetNames{iFile};
    startRow = 12;
    endRow = endRows(iFile);

    [TimeSec,HR,Work,VO2,VO2kg,VCO2,RQ,VEbtps,RTrest,Level] = ...
        importTemp(workbookFile,sheetName,startRow,endRow);


    % Flag rows for level E or "Exercise" challenge, called 'idx'
    idx = false(length(TimeSec),1);
    for iRow = 1:length(TimeSec)
        if isequal(Level{iRow},'E')
            idx(iRow) = true(1);
        end
    end

    % Take time from exercise level
    Time = TimeSec(idx);

    % Convert time values to decimals of exercise, simply called 'TimeSec_exe'
    TimeSec_exe = zeros(length(Time),1);
    TimeSec_formatted = cell(length(Time),1);
    for iRow = 1:length(Time)
        currentRow = datestr(Time(iRow) + 693960, 13);
        currentRow = str2double(regexp(currentRow,':','split'));
        currentRow = currentRow*[60^2;60;1];
        TimeSec_exe(iRow) = currentRow;
        TimeSec_formatted{iRow} = datestr(Time(iRow) + 693960, 13);
    end

    % Get VO2 from exercise level
    VO2_exe = VO2(idx);

    % Determine if VO2_exe reaches a 'plateau'
    % Currently set to a fraction of max of the first derivative of a 
    % loosely fit third degree polynomial 
    p = polyfit(TimeSec_exe,VO2_exe,3);
    pder = polyder(p);
    xev = 0:2:TimeSec_exe(end);
    yder = polyval(pder,xev);
    ratio = (yder(end)/max(yder));
    fraction = 0.5;
    if ratio <= fraction
        plateau{iFile} = 'true';
    end
    
    
    % Window data to remove noise
    windowlength = 20;
    windowhalflength = windowlength*0.5;
    windowmean = double(1); % reinitialize windowmean
    for iRow = 1:length(TimeSec_exe) % Sliding window
        if TimeSec_exe(iRow) >= windowhalflength && ...
                TimeSec_exe(iRow) <= (max(TimeSec_exe)-windowhalflength);
            lowerValue = TimeSec_exe(iRow) - windowhalflength;
            upperValue = TimeSec_exe(iRow) + windowhalflength;
            [~,idxLower] = min(abs(TimeSec_exe-lowerValue));
            [~,idxUpper] = min(abs(TimeSec_exe-upperValue));
            % Mean Time
            windowmean(iRow) = mean(VO2_exe(idxLower:idxUpper)); %#ok<SAGROW>
        else
            windowmean(iRow) = NaN; %#ok<SAGROW>
        end
    end

    peakVO2(iFile) = max(windowmean);
    peakRQ(iFile)  = max(RQ(idx));
    peakHR(iFile)  = max(HR);
end
plateau = transpose(plateau);
peakVO2 = transpose(peakVO2);
peakRQ = transpose(peakRQ);
peakHR = transpose(peakHR);