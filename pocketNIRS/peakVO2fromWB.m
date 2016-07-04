% Ver 4-22-16 Brian
%% Metabolic cart data processing for pocketNIRS
% This script automatically collects and calculates relevant data from the
% metabolic cart. It will output the data into a condensed table.

%% Create input variables
% Given the current input format, an import function that collects and
% cleans the metabolic cart data into a cell array is used. This import
% function requires the names of the sheets (patient IDs) and the number of
% rows of data to collect.

%% 
%PAMP1
workbookFile = 'PS work rate calculations.xlsx';
load pamp1.mat

% %%
% % FSHR Cohort 5
% workbookFile = 'Cohort5 V1 VO2 calculations.xlsx';
load fshr5.mat

% %% PAMP 2
% workbookFile = 'PS 2 work rate calculations.xlsx';
load pamp2.mat
    

%% Input consistency check
% Continue only if input length for two variables match in length
if length(endRows) ~= length(sheetNames)
    error('Mismatch between sheet names and number of rows for each subject')
end


%% Create collection variables
numberOfParticipants = length(endRows);

peakWork = zeros(numberOfParticipants,1);
peakVO2 = zeros(numberOfParticipants,1);
peakRQ  = zeros(numberOfParticipants,1);
peakHR  = zeros(numberOfParticipants,1);
time_halfpeakVO2 = zeros(numberOfParticipants,1);

% value at start of exercise
start_HR = zeros(numberOfParticipants,1);
start_Work = zeros(numberOfParticipants,1);
start_VO2 = zeros(numberOfParticipants,1);
start_VO2kg = zeros(numberOfParticipants,1);
start_VCO2 = zeros(numberOfParticipants,1);
start_RQ = zeros(numberOfParticipants,1);

% value at 50% peakVO2
halfpeak_HR = zeros(numberOfParticipants,1);
halfpeak_Work = zeros(numberOfParticipants,1);
halfpeak_VO2 = zeros(numberOfParticipants,1);
halfpeak_VO2kg = zeros(numberOfParticipants,1);
halfpeak_VCO2 = zeros(numberOfParticipants,1);
halfpeak_RQ = zeros(numberOfParticipants,1);

% halfpeak - start values
delta_HR = zeros(numberOfParticipants,1);
delta_Work = zeros(numberOfParticipants,1);
delta_VO2 = zeros(numberOfParticipants,1);
delta_VO2kg = zeros(numberOfParticipants,1);
delta_VCO2 = zeros(numberOfParticipants,1);
delta_RQ = zeros(numberOfParticipants,1);

% slopes from start of exercise to half peak
coef_HR = zeros(numberOfParticipants,2);
coef_Work = zeros(numberOfParticipants,2);
coef_VO2 = zeros(numberOfParticipants,2);
coef_VO2kg = zeros(numberOfParticipants,2);
coef_VCO2 = zeros(numberOfParticipants,2);
coef_RQ = zeros(numberOfParticipants,2);



%% File loop
for iFile = 1:numberOfParticipants        
    % Import
   
    sheetName = sheetNames{iFile};
    startRow = 12;
    endRow = endRows(iFile);

    [TimeSec,HR,Work,VO2,VO2kg,VCO2,RQ,VEbtps,RTrest,Level] = ...
        importMetabolicCartData(workbookFile,sheetName,startRow,endRow);


    % Flag rows for level E or "Exercise" challenge, called 'idx'
    idx = false(length(TimeSec),1);
    for iRow = 1:length(TimeSec)
        if isequal(Level{iRow},'E')
            idx(iRow) = true(1);
        end
    end

    % Take time from exercise level
    Time = TimeSec(idx);
    
    % Subset data from other variables of interest with exercise level
    exe_HR = HR(idx);
    exe_Work = Work(idx);
    exe_VO2 = VO2(idx); 
    exe_VO2kg = VO2kg(idx);
    exe_VCO2 = VCO2(idx);
    exe_RQ = RQ(idx);
    

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


    % Window data to remove noise
    windowlength = 20;
    windowhalflength = windowlength*0.5;
    % reinitialize windowmean collection var
    windowmean = zeros(1,length(TimeSec_exe)); 
    % sliding window
    for iRow = 1:length(TimeSec_exe) 
        if TimeSec_exe(iRow) >= windowhalflength && ...
                TimeSec_exe(iRow) <= (max(TimeSec_exe)-windowhalflength);
            lowerValue = TimeSec_exe(iRow) - windowhalflength;
            upperValue = TimeSec_exe(iRow) + windowhalflength;
            [~,idxLower] = min(abs(TimeSec_exe-lowerValue));
            [~,idxUpper] = min(abs(TimeSec_exe-upperValue));
            % Mean Time
            windowmean(iRow) = mean(exe_VO2(idxLower:idxUpper)); 
        else
            windowmean(iRow) = NaN; 
        end
    end
    
    % Get peak values
    peakVO2(iFile) = max(windowmean);
    peakRQ(iFile)  = max(exe_RQ);
    peakHR(iFile)  = max(exe_HR);
    peakWork(iFile) = max(exe_Work);
    
    
    % Determine time at 50% VO2 peak, called 'TimeSec_exe_halfpeak'
    [~,idx_peakVO2] = max(windowmean);
    idx_halfpeakVO2 = ceil(idx_peakVO2*0.5);
    time_halfpeakVO2(iFile) = TimeSec_exe(idx_halfpeakVO2);
    
    
    % Get slope of data from 0 to 50% VO2 peak
    coef_HR(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                exe_HR(1:idx_halfpeakVO2),1);
    coef_Work(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                    exe_Work(1:idx_halfpeakVO2),1);
    coef_VO2(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                    exe_VO2(1:idx_halfpeakVO2),1);      
    coef_VO2kg(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                    exe_VO2kg(1:idx_halfpeakVO2),1); 
    coef_VCO2(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                    exe_VCO2(1:idx_halfpeakVO2),1);
    coef_RQ(iFile,1:2) = polyfit(TimeSec_exe(1:idx_halfpeakVO2),...
                    exe_RQ(1:idx_halfpeakVO2),1);
                 
    % Get value at start of exercise challenge
    start_HR(iFile) = exe_HR(1);
    start_Work(iFile) = exe_Work(1);
    start_VO2(iFile) = exe_VO2(1);
    start_VO2kg(iFile) = exe_VO2kg(1);
    start_VCO2(iFile) = exe_VCO2(1);
    start_RQ(iFile) = exe_RQ(1);
                
    % Get value at 50% peak VO2 for data of interest
    halfpeak_HR(iFile) = exe_HR(idx_halfpeakVO2);
    halfpeak_Work(iFile) = exe_Work(idx_halfpeakVO2);
    halfpeak_VO2(iFile) = exe_VO2(idx_halfpeakVO2);
    halfpeak_VO2kg(iFile) = exe_VO2kg(idx_halfpeakVO2);
    halfpeak_VCO2(iFile) = exe_VCO2(idx_halfpeakVO2);
    halfpeak_RQ(iFile) = exe_RQ(idx_halfpeakVO2);
    
    % Get delta value for data of interest from other variables
    delta_HR(iFile) = exe_HR(idx_halfpeakVO2)-exe_HR(1);
    delta_Work(iFile) = exe_Work(idx_halfpeakVO2)-exe_Work(1);
    delta_VO2(iFile) = exe_VO2(idx_halfpeakVO2)-exe_VO2(1);
    delta_VO2kg(iFile) = exe_VO2kg(idx_halfpeakVO2)-exe_VO2kg(1);
    delta_VCO2(iFile) = exe_VCO2(idx_halfpeakVO2)-exe_VCO2(1);
    delta_RQ(iFile) = exe_RQ(idx_halfpeakVO2)-exe_RQ(1);
    

end % end file loop

%% Combine
T_Input = dataset(endRows,'ObsNames',sheetNames);
T1 = dataset(peakWork,peakVO2,peakRQ,peakHR,time_halfpeakVO2,'ObsNames',sheetNames);
T2 = dataset(start_HR,start_Work,start_VO2,start_VO2kg,start_VCO2,...
    start_RQ,'ObsNames',sheetNames);
T3 = dataset(halfpeak_HR,halfpeak_Work,halfpeak_VO2,halfpeak_VO2kg,...
    halfpeak_VCO2,halfpeak_RQ,'ObsNames',sheetNames);
T4 = dataset(delta_HR,delta_Work,delta_VO2,delta_VO2kg,delta_VCO2,delta_RQ,...
    'ObsNames',sheetNames);
T5 = dataset(coef_HR,coef_Work,coef_VO2,coef_VO2kg,coef_VCO2,coef_RQ,...
    'ObsNames',sheetNames);
T_output = horzcat(T_Input,T1,T2,T3,T4,T5);

%% Output to excel
output_fid = 'ExerciseOutput.csv';
export(T_output,'file',output_fid,'Delimiter',',');
