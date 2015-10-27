%% Data collection scripts for DOSI and metabolic cart data
% This script first collects optical and metabolic cart data, 
% combines them into study-specific .mat files, then stratifies the data 
% into study phases related to exercise. Twenty-second bins and raw data
% are output. The user must input which study marker corresponds with each
% study phase in an automatically generated workbook (DOSI&Bike_input.xlsx)
% within the working directory prior to completing data cleanup.
%
% During this process, SLM engine is invoked for breakpoint analyis;
% figures are output, then relative work-rate is calculated.
%
% Raw data (directly from TRS) should be named in the following pattern: 
%   EXO-03 AmMa V1 03-12-14 Bike *
%   EXO-00 AnGo V6 09-05-14 DataSource *
%
%   * = wildcard; can be any additional study information (e.g.
%       EXO-00 AnGo V4 08-27-14 V4_PFC_4cm_15W_FAD would work)
%
%   Additional Points on file naming:
%   - Datasource can be Brain, Muscle, PFC, or VL
%   - Any study without a Bike or Brain modifier will be treated as PFC
%   data. See example .zip for more details.
%
% Metabolic cart data should be set up with the following data columns
% (labels don't matter, just order from left to right):
% 	Time(Min)
% 	Work	
%	VO2	
%	VO2/kg
%	VCO2
%	RQ
%	VE(BTPS)
%	RR
%	HR
%	RPM
%	PetO2
%	PetCO2
%	VEO2
%	VECO2
%
% Work-rate key time-points (e.g. E20,E40) and threshold relative to total
% ramp times are currently not output.
%
% Required functions/packages: Shape Language Modeling by John D'Errico
% Updated 10-26-15 Brian

%% Convert CSV to MAT and plot figures to correspond markers with study phase
% Given a working directory with .csv data files from the metabolic cart
% and DOSI device, identify the file type, assign data to variables,
% and make a copy of the data following a binning procedure.
% Almost all of the variables are assigned to a structure for access via
% variable names later.
disp('Converting CSV to MAT and plot figures to correspond markers with study phase')
clearvars
csvFiles = dir('*.csv');

% Make new folder to save MAT converted files
currDir = pwd;
if exist([pwd '\MAT Output'],'dir') == 0
    mkdir('MAT Output')
end

for iFiles = 1:length(csvFiles);
    currFile = importdata(csvFiles(iFiles).name);
    csvData = currFile;
    currFileName = mat2str(csvFiles(iFiles).name);

    % Distinguish between FAD/FAC DOSI and Bike/Cart data via file name
    if isempty(strfind(currFileName,'Bike')) == 1

        % Raw Data
        VariableData.Raw.HbO2 = currFile.data(:,37);
        VariableData.Raw.HbR  = currFile.data(:,39);
        VariableData.Raw.THb  = currFile.data(:,41);
        VariableData.Raw.stO2 = currFile.data(:,43);

        VariableData.Raw.time    = currFile.data(:,1);
        VariableData.Raw.markers = currFile.data(:,3);

        VariableData.Raw.SC1 = currFile.data(:,31);
        VariableData.Raw.SC2 = currFile.data(:,33);
        VariableData.Raw.SC3 = currFile.data(:,35);
        VariableData.Raw.AC1 = currFile.data(:,25);
        VariableData.Raw.AC2 = currFile.data(:,27);
        VariableData.Raw.AC3 = currFile.data(:,29);
        VariableData.Raw.PL1 = currFile.data(:,22);
        VariableData.Raw.PL2 = currFile.data(:,23);
        VariableData.Raw.PL3 = currFile.data(:,24);

    elseif isempty(strfind(currFileName,'Bike')) == 0

        VariableData.Raw.time = currFile.data(:,1);
        VariableData.Raw.W    = currFile.data(:,2);
        VariableData.Raw.VO2  = currFile.data(:,3);
        VariableData.Raw.VOK  = currFile.data(:,4);
        VariableData.Raw.VCO2 = currFile.data(:,5);
        VariableData.Raw.RQ   = currFile.data(:,6);
        VariableData.Raw.VE   = currFile.data(:,7);
        VariableData.Raw.RR   = currFile.data(:,8);
        VariableData.Raw.HR   = currFile.data(:,9);
        VariableData.Raw.RPM  = currFile.data(:,10);
        VariableData.Raw.PO   = currFile.data(:,11);
        VariableData.Raw.PC   = currFile.data(:,12);
        VariableData.Raw.VEO  = currFile.data(:,13);
        VariableData.Raw.VEC  = currFile.data(:,14);

    else
        fprintf('Unrecognized data file error on %s \n',currFileName);
    end



    % Generate study identifier variable
    fileName = strrep(currFileName,'.csv','');
    fileName = strrep(fileName,'''','');
    fileNameOutput = strsplit(fileName,' ');

    disp([' ' fileName])

    % Save all variables except those listed below
    cd([currDir '\Mat Output'])
    save(fileName, '-regexp', '^(?!(csvFiles|iFiles|currFile|currFileName)$).')
    cd(currDir)
    
    % clearvars variables except those necessary to continue
    clearvars -except csvFiles...
                      indFiles...
                      currDir
end

%% Generate input.csv to input marker/study phase data
% Generate input.csv for manual study phase determination. Only selects
% data files from DOSI containing 'Brain,PFC,Muscle,VL' within the
% filename. 
% Each section should have a columnn and the numbers should match with the 
% marker index (e.g. 1-5, representing the first to fifth marker as each 
% point). Note that only the first sheet, labeled 'input', is the only 
% sheet used for data assignment.

% Switch to MAT output directory
currDir = pwd;
cd([currDir '\MAT Output'])

% Pre-allocate and generate file list
matfiles = dir('*.mat');
matarr   = struct2cell(matfiles);
matnames = transpose(matarr(1,:));

headers = {'filename',...
           'rampBeg',...
           'rampEnd',...
           'pedalingStart',...
           'recoveryStart',...
           'pedalingEnd'};
       
emptyMarkers = cell(size(matnames,1),size(headers,2)-1);
matnames = horzcat(matnames,emptyMarkers);

% Valid file index position is kept using an index generated via regex.
% This is crucial to assigning the correct ramp data to a particular data
% file in the case that the working directory contains invalid files.

indValidDataFiles = regexp(matnames,'^(?!.*(Brain|PFC|Muscle|VL)).*');
for iMatNames = 1:length(matnames)
    if cell2mat(indValidDataFiles(iMatNames)) == 1
        % Fill in phase data for non-optical data files with a marker
        matnames(iMatNames,2:end) = {0};
    end
end


% Switch back to data directory
cd(currDir)

% Excel Output
filename = 'DOSI&Bike_input.xlsx';
xlswrite(filename,headers,2,'A1');
xlswrite(filename,matnames,2,'A2');
fprintf('\nGenerated input.xlsx in current directory from csv files in current directory:\n')
disp(currDir)
fprintf('\nNote: New data is in 2nd sheet of DOSI&Bike_input.xlsx \n')

% Open ActiveX COM server to rename excel sheets
e = actxserver('Excel.Application'); 
    ewb = e.Workbooks.Open([currDir '\' filename]);
    ewb.Worksheets.Item(1).Name = 'input';
    ewb.Worksheets.Item(2).Name = 'new ordered matfiles';
    ewb.Save
    ewb.Close(false);
    e.Quit

% Cleanup
clearvars matfiles...
          mattarr...
          matnames...
          headers...
          e...
          emptyMarkers...
          ewb...
          iMatNames...
          indValidDataFiles...
          matarr...
          combinedFilenamesHeaders

%% Generate figures to locate study phases (DOSI Processing)
% After generating mat files, plot Hb and Marker data for every optical
% data file. In a new subdirectory called, "Study Phase Plots." This is 
% useful to correspond study phase data (i.e. ramp, recovery) with 
% study markers.

fprintf('\nGenerating figures to locate study phases\n')

currDir = pwd;

% Make figures folder if it doesn't exist and set current directory 
if exist([currDir '\Study phase plots'],'dir') == 0
    mkdir('Study phase plots')
end

% Switch to MAT output directory
cd([currDir '\MAT Output'])

% Generate file list
matfiles = dir('*mat');

% File list loop
for iM = 1:numel(matfiles)
    % Load current file
    load(matfiles(iM).name);
    disp([' ' fileName])
    try
        % Only generate figures for optical data
        if isempty(strfind(fileName,'Bike')) == 1

            close all

            % Make figure
            figure;
            set(gcf,'Visible','off', 'Color', 'w');
            [hAx,~,~] = plotyy(VariableData.Raw.time,VariableData.Raw.HbR,VariableData.Raw.time,VariableData.Raw.markers);
            title(sprintf('%s',strrep(fileName,'_',' ')))
            xlabel('Time (minutes)');
            ylabel(hAx(1),'HbR (µM)');
            ylabel(hAx(2),'Marker');

            % Manually set marker ticks for easier visualization
            maxTick  = max(VariableData.Raw.markers);
            numTicks = numel(find(VariableData.Raw.markers));
            markerTicks = linspace(1,maxTick,numTicks);
            set(hAx(2),'YTick',markerTicks);



            % Save into new folder
            cd([currDir '\Study phase plots'])
            export_fig(sprintf('%s',fileName),'-png','-m2');
            cd([currDir '\MAT Output'])
        end
    
    catch StudyPhaseLoopErr
        continue
    end
end

% Switch back to data directory
cd(currDir)

% Cleanup
% Remove all workspace variables to prevent the study variables from
% being partially overwritten.
clearvars

%% Require user input prior to continuing
prompt = '\n Have the study phases been located and entered into the input\n workbook? Press enter to continue. \n';
x = input(prompt);

%% Load input.xlsx
% Load manually located study phases from 'DOSI&Bike_input.xlsx' prior to
% starting the batch loop.

studyPhases     = importdata('DOSI&Bike_input.xlsx');
fileList        = studyPhases.textdata.input(2:end,1);
inRampBeginning = studyPhases.data.input(:,1);
inRampEnd       = studyPhases.data.input(:,2);
inPedalingStart = studyPhases.data.input(:,3);
inRecoveryStart = studyPhases.data.input(:,4);
inPedalingEnd   = studyPhases.data.input(:,5);

%% Study loop to stratify data based on markers
% After loading the input file (with corresponding marker and study phase 
% data), compile variables into a superstructure variable. This section
% separates optical data and bike data, stratifies the optical
% data based into study phases based on marker data, identifies data
% at key work-rate time points, and runs the SLM analysis.
fprintf('Organizing and assigning data to structure variable...\n');

% Switch to MAT output directory
currDir = pwd;
cd([currDir '\MAT Output'])

% Generate file list
matfiles = dir('*mat');

% File list loop
for iM = 1:numel(matfiles)
    if length(matfiles) ~= length(fileList)
        warning('Loop stopped. Mismatch between input.xlsx and number of files in working directory.')
    break
    end
    try
    % Load current file
    load(matfiles(iM).name);
    
    % Load study identifiers
    initial = fileNameOutput{2};
    visit   = fileNameOutput{3};
    date    = ['ddmmyy',fileNameOutput{4}]; % Only used to confirm visit # if req

    % Remove dashes in date format to be compatible with structure variable
    date = strrep(date,'-','');
    
    disp([' ' fileName])
    % EXO-03 AmMa V1 03-12-14 Bike *
    % EXO-00 AnGo V6 09-05-14 Brain *

    % Stratify data based on file name and assign to structure variable

    % For optical data: 
    if isempty(strfind(fileName,'Bike')) == 1 && ...
       inRampBeginning(iM) ~= 0 % 0 is the marker for non-optical data

        % Set to label to brain (vestige variable from VL & PFC processing)
        if isempty(strfind(fileName,'Brain')) == 0 || ...
           isempty(strfind(fileName,'PFC'))   == 0
           
           pfcORvl = 'Brain';
        
        elseif isempty(strfind(fileName,'Muscle')) == 0 || ...
               isempty(strfind(fileName,'VL'))   == 0 
        
           pfcORvl = 'Muscle';
        
        end
        
        % Set label to FAD (vestige variable from FAD & FAC processing)    
        fadORfac = 'FAD';
        
        % Set default data type (binned or raw)
        currDataType = 'Raw';
   
       % Stratify data based on marker input % 

       % Load marker variables for optical data
        indMarker     = find(VariableData.(currDataType).markers);
        rampBeginning = indMarker(inRampBeginning(iM));
        rampEnd       = indMarker(inRampEnd(iM));
        pedalingStart = indMarker(inPedalingStart(iM));
        recoveryStart = indMarker(inRecoveryStart(iM));
        pedalingEnd   = indMarker(inPedalingEnd(iM));

       % Define phases via marker data
        allphases      = (1:length(VariableData.(currDataType).time));
        baselinePhase  = (1:pedalingStart);    
        rampPhase      = (rampBeginning:rampEnd);
        recoveryPhase  = (recoveryStart:length(VariableData.(currDataType).time));
        combPhaseArray = {allphases;baselinePhase;rampPhase;recoveryPhase};
        phaseHeaders   = {'AllPhases','Baseline','Ramp','Recovery'};

        % Assign Variable Data
        vars = fieldnames(VariableData.(currDataType));
        for iPhase = 1:length(combPhaseArray)
            currPhase = phaseHeaders{iPhase};
            
            % Raw Data
            for iVar = 1:length(fieldnames(VariableData.(currDataType)));
                currVar = vars{iVar};

                % To superstructure
                ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.(currPhase).(currVar) = ...
                    VariableData.(currDataType).(currVar)(combPhaseArray{iPhase});

                % To current MAT file
                ProcessedData.StudyPhases.(currPhase).(currVar) = ....
                    VariableData.(currDataType).(currVar)(combPhaseArray{iPhase}); 
            end
            
            % Binned Data
                
            % Define binning parameters based on study phase time axis data
            timeAxis = ExeDOSI.(initial).(visit).(date).(pfcORvl).Raw.(fadORfac).StudyPhases.(currPhase).time;
            topEdge = max(timeAxis); 
            botEdge = min(timeAxis);
            numBins = ceil(max(timeAxis)*(3)); % 20 sec bins, given axis (min)
            binEdges = linspace(botEdge, topEdge, numBins+1);
            [h,whichBin] = histc(timeAxis, binEdges);
            
            % Bin available variables in study phase
            indBinningVars = fieldnames(ExeDOSI.(initial).(visit).(date).(pfcORvl).Raw.(fadORfac).StudyPhases.(currPhase));
            for iRawData = 1:length(fieldnames(ExeDOSI.(initial).(visit).(date).(pfcORvl).Raw.(fadORfac).StudyPhases.(currPhase)))

                % Define variable to be binned
                currVarToBin     = indBinningVars{iRawData};
                currVarToBinData = ExeDOSI.(initial).(visit).(date).(pfcORvl).Raw.(fadORfac).StudyPhases.(currPhase).(indBinningVars{iRawData});

                % Populate new time axis with corresponding response variable data
                binMean = zeros(numBins,1);
                for iBins = 1:numBins
                    flagBinMembers = (whichBin == iBins);
                    binMembers     = currVarToBinData(flagBinMembers);
                    binMean(iBins) = mean(binMembers);
                end

                % Assign binned data
                 ExeDOSI.(initial).(visit).(date).(pfcORvl).Binned.(fadORfac).StudyPhases.(currPhase).(currVarToBin) = ...
                     binMean;

            end % End binning procedure
        end % End raw/binned/workRate data assignment by study phase

        
        % Work rate key time-points for raw/binned ramp data only %
        indDataType = fieldnames(ExeDOSI.(initial).(visit).(date).(pfcORvl));
        for iDataType = 1:size(indDataType);
        currDataTypeWR = indDataType{iDataType};

            for iPhase = 1:length(combPhaseArray)
            currPhaseWR = phaseHeaders{iPhase};

                if strcmp(currPhaseWR,'Ramp') == 1
                    % Define work-rate time-points
                    workRateHeaders    = {'E0','E20','E40','E60','E80','EM'};
                    sizeVariableInd    = size(ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataTypeWR).(fadORfac).StudyPhases.Ramp.time,1);
                    workRateMultiplier = [1/sizeVariableInd,.2,.4,.6,.8,1];
                    indWorkRate        = ceil(sizeVariableInd*workRateMultiplier);

                    % Assign Variable Data
                    for iWorkRate = 1:size(workRateHeaders,2)
                        currWorkRate        = indWorkRate(iWorkRate);
                        currWorkRateHeader  = workRateHeaders{iWorkRate};
                        vars                = fieldnames(ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataTypeWR).(fadORfac).StudyPhases.Ramp);
                        for iVar = 1:length(vars)
                            currVar = vars{iVar};

                            % To superstructure
                            ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataTypeWR).(fadORfac).VarWorkRate.(currWorkRateHeader).(currVar) = ...
                               ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataTypeWR).(fadORfac).StudyPhases.Ramp.(currVar)(currWorkRate);

                            % To current MAT file
                            ProcessedData.VarWorkRate.(currVar)(currWorkRate) = ...
                                ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataTypeWR).(fadORfac).StudyPhases.Ramp.(currVar)(currWorkRate);
                        end
                    end
                end % end Ramp workrate data assignment
            end % end Phase loop
        end % end binned/raw loop
        

        % Generate SLM figures %
        % Warning: Figure generation in this section will dramatically 
        % increase processing time (e.g. for one subject: from 5 seconds 
        % to 1 minute). Consider commenting out the following 'save figure'
        % section if you only require the numerical data.
        % 
        % *Since the threshold analysis is run only on the ramp data, the
        % ramp data generated in the previous section is required

        % Generate figure directory
        if exist([currDir '\SLM Plots'],'dir') == 0
            cd(currDir)
            mkdir('SLM Plots')
            cd([currDir '\MAT Output'])
        end

        % Assign data and generate figures
        slmProgress = sprintf('\n Running SLM analysis for %s \n', fileName);
        disp(slmProgress)
        
        vars = fieldnames(ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.Ramp);
        analyzeThis = {'HbO2','HbR','THb','stO2'}; % Look at these vars
        for iVar = 1:length(vars)
            currVar = vars{iVar};
            if any(strncmp(currVar,analyzeThis,4)) == 1

            % Assign Variable Data

            % To superstructure

            % SLM Function
            ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).SLMFigures.(currVar) = ...
                slmengine(ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.Ramp.time,...
                          ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.Ramp.(currVar),...
                          'plot','off','degree',1,'interior','free','knots',4);
                % Time in generated ramp data, current variable in ramp data

            % for Comparison to Bike function
            normalizedRampTime = ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.Ramp.time -...
                ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).StudyPhases.Ramp.time(1);


            % To current MAT file    
            if strncmp(currDataType,'Binned',6) == 1;
            ProcessedData.SLMFigures.(currVar)(currWorkRate) = ...
                ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).SLMFigures.(currVar);
            end

            % Save figure
                currPlot = ExeDOSI.(initial).(visit).(date).(pfcORvl).(currDataType).(fadORfac).SLMFigures.(currVar);
                    slmFig = plotslm(currPlot);
                    title(sprintf('SLM Fit for %s - %s',strrep(fileName,'_',' '),currVar));
                    set(gcf,'Visible','off', 'Color', 'w');
                cd([currDir '\SLM Plots'])
                    export_fig(sprintf('%s - %s',strrep(fileName,'_',' '),currVar),'-png','-m1');
                cd([currDir '\MAT Output'])
                
            else
                continue
            end
        end       

    % For Bike data:
    elseif isempty(strfind(fileName,'Bike')) == 0
        
        % Set default data type (binned or raw)
        currDataType = 'Raw';

        % Assign Variable Data
        vars = fieldnames(VariableData.(currDataType));
        for iVar = 1:length(vars)
            currVar = vars{iVar};

            % To superstructure
            ExeDOSI.(initial).(visit).(date).Bike.(currDataType).(currVar) = ...
                VariableData.(currDataType).(currVar);

            % To current MAT file
            ProcessedData.Bike = VariableData.(currDataType).(currVar);
        end

    % For matfiles not recognized as bike or optical data:
    else
        fprintf('Unrecognized file: %s \n',studyPhases.textdata.input{iM+1});
    end
        % Append processed data to current .mat file
        % save(fileName,'ProcessedData','-append'); 
    % 


    
    catch FileLoopErr
        fprintf('(%g/%g) Study loop error on %s \n',iM,numel(matfiles),fileName);
        continue
    end
end

% Switch back to data directory
cd(currDir)

% Export structure variable to a .mat file

filename3 = 'ExeDOSI.mat';

% Export current time
timeGenerated = datestr(now);

% Make folder and set current directory if it doesn't exist
if exist([currDir '\Structure Var Output'],'dir') == 0
    cd(currDir)
    mkdir('Structure Var Output')
end

% Save into new folder
cd([currDir '\Structure Var Output'])
save(filename3, 'ExeDOSI','timeGenerated');
fprintf('\nSaved data to structure variable.\n');
cd(currDir)

%% Generate output for R analysis
% Creates an output suitable for Goutham's R threshold analysis script via
% accessing the data in the ExeDOSI superstructure variable.

% Loop structure 
% Optical: ExeDOSI.(initial).(visit).date.(pfcORvl).Raw.(fadORfac).StudyPhases.(currPhase).(currVar)
% Bike: ExeDOSI.(initial).(visit).date.Bike.Raw.(currVar)

fprintf('\nGenerating re-organized CSV files for R threshold analysis: \n')

% Make output folder and set current directory if it doesn't exist
currDir = pwd; 
if exist([pwd '\CSV Output'],'dir') == 0
    mkdir('CSV Output')
end

% Access the data for all subjects from ExeDOSI superstructure

% Subject Initials
indInitials = fieldnames(ExeDOSI);
for iInitials = 1:length(indInitials);
    currInitials = indInitials{iInitials};
    indVisits = fieldnames(ExeDOSI.(currInitials));
    
    % Subject Visits
    for iVisits = 1:length(indVisits);
        currVisit = indVisits{iVisits};
        indDates = fieldnames(ExeDOSI.(currInitials).(currVisit));
        
        % Dates (e.g. if there are multiple V3's etc.)
        for iDates = 1:length(indDates);
            currDate = indDates{iDates};
            indPFCorVL = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate));
           
            % Brain or Muscle
            for iPFCorVL = 1:length(indPFCorVL);
                currPFCorVL = indPFCorVL{iPFCorVL};
                
                % Display current study
                disp([' ' currInitials '_' currVisit '_' currPFCorVL])
               
                % Binned or Raw data
                indCurrDataType = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate).(currPFCorVL));
                for iCurrDataType = 1:length(indCurrDataType)
                    currDataType = indCurrDataType{iCurrDataType};
                    
                % Optical/bike data loops
                OpticalIdentifier  = {'Brain','Muscle'};
                ExerciseIdentifier = {'Bike'};
                    if any(strncmp(currPFCorVL,OpticalIdentifier,4)) == 1
                        indFADorFAC = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate).(currPFCorVL).(currDataType));

                        if any(strcmp('FAD',indFADorFAC)) == 1
                        % Temp Structure for FAD output conforming to
                        % Goutham's R scripts (rearranged to exclude FAC data)
                        tempStruct  = [ExeDOSI.(currInitials).(currVisit).(currDate).(currPFCorVL).(currDataType).FAD.StudyPhases.Ramp];

                        outputArr       = zeros(length(tempStruct(1,1).time),14);
                        outputArr(:,1)  = tempStruct(1,1).time;
                        outputArr(:,2)  = tempStruct(1,1).HbO2;
                        outputArr(:,3)  = tempStruct(1,1).HbR;
                        outputArr(:,4)  = tempStruct(1,1).THb;
                        outputArr(:,5)  = tempStruct(1,1).stO2;
                        outputArr(:,6) = tempStruct(1,1).SC1;
                        outputArr(:,7) = tempStruct(1,1).SC2;
                        outputArr(:,8) = tempStruct(1,1).SC3;
                        outputArr(:,9) = tempStruct(1,1).AC1;
                        outputArr(:,10) = tempStruct(1,1).AC2;
                        outputArr(:,11) = tempStruct(1,1).AC3;
                        outputArr(:,12) = tempStruct(1,1).PL1;
                        outputArr(:,13) = tempStruct(1,1).PL2;
                        outputArr(:,14) = tempStruct(1,1).PL3;

                        headers = {'time',...
                                   'HbO2',...
                                   'HbR',...
                                   'THb',...
                                   'stO2',...
                                   'SC1',...
                                   'SC2',...
                                   'SC3',...
                                   'AC1',...
                                   'AC2',...
                                   'AC3',...
                                   'PL1',...
                                   'PL2',...
                                   'PL3',...                              
                                   };

                        %Output datatable to .csv
                        if any(strcmp('Raw',currDataType)) == 1
                        filename = [currInitials ' ' currVisit ' ' strrep(currDate,'ddmmyy','') ' ' currPFCorVL ' MAT' '.csv']; 
                        else
                            filename = [currInitials ' ' currVisit ' ' strrep(currDate,'ddmmyy','') ' ' currPFCorVL ' MAT' ' Binned' '.csv']; 
                        end
                        csv = sprintf('%s,',headers{:});
                        csv(end) = '';
                        cd([currDir '\CSV Output'])
                        dlmwrite(filename,csv,'');
                        dlmwrite(filename,outputArr,'-append','delimiter',',');
                        cd(currDir)
                        end
                    % Exercise data only loop
                    elseif any(strncmp(indPFCorVL,ExerciseIdentifier,4)) == 1
                        % Temp Structure for exe data output conforming to
                        % Goutham's R scripts
                        tempStruct = ExeDOSI.(currInitials).(currVisit).(currDate).Bike.(currDataType);
                        outputArr       = zeros(length(tempStruct.time),13);
                        outputArr(:,1)  = tempStruct.time;
                        outputArr(:,2)  = tempStruct.VEO;
                        outputArr(:,3)  = tempStruct.VEC;
                        outputArr(:,4)  = tempStruct.PO;
                        outputArr(:,5)  = tempStruct.PC;
                        outputArr(:,6)  = tempStruct.VO2;
                        outputArr(:,7)  = tempStruct.VOK;
                        outputArr(:,8)  = tempStruct.VCO2;
                        outputArr(:,9)  = tempStruct.VE;
                        outputArr(:,10)  = tempStruct.HR;
                        outputArr(:,11)  = tempStruct.RR;
                        outputArr(:,12)  = tempStruct.RPM;
                        outputArr(:,13)  = tempStruct.W;

                        headers = {'time',...
                                   'VEO',...
                                   'VEC',...
                                   'PO',...
                                   'PC',...
                                   'VO2',...
                                   'VOK',...
                                   'VCO2',...
                                   'VE',...
                                   'HR',...
                                   'RR',...
                                   'RPM',...
                                   'Work',...                          
                                   };

                   %Output datatable to .csv
                   if any(strcmp('Raw',currDataType)) == 1
                    filename = [currInitials ' ' currVisit ' ' strrep(currDate,'ddmmyy','') ' ' 'Exe' ' MAT' '.csv']; 
                   else
                    filename = [currInitials ' ' currVisit ' ' strrep(currDate,'ddmmyy','') ' ' 'Exe' ' MAT' ' Binned' '.csv']; 
                   end
                    csv = sprintf('%s,',headers{:});
                    csv(end) = '';
                    cd([currDir '\CSV Output'])
                    dlmwrite(filename,csv,'');
                    dlmwrite(filename,outputArr,'-append','delimiter',',');
                    cd(currDir)

                    else
                       % Found neither optical or exe data
                       
                    end % End Bike/Optical loops
                end % End binned/raw loop
            end % End PFC or VL loop
        end % End dates loop
    end % End visits loop
end % End subject loop

%% Comparisons between bike and optical data
% Processing loop for ExeDOSI structure variable. Procedures can be made
% to loop at any level of the structure (e.g. subject-wise analysis,
% optical or exercise-only analysis, etc.)
%
% Current functions:
%   1) Matching DOSI with equivalent exercise data, obtain relative 
%      threshold timing (e.g. fraction of ramp)
%   2) Save output to ExeDOSI structure variable

% Subject Initials
fprintf('\nSaving data from comparison procedures... \n')

indInitials = fieldnames(ExeDOSI);
for iInitials = 1:length(indInitials);
    currInitials = indInitials{iInitials};
    indVisits = fieldnames(ExeDOSI.(currInitials));
    
    % Subject Visits
    for iVisits = 1:length(indVisits);
        currVisit = indVisits{iVisits};
        indDates = fieldnames(ExeDOSI.(currInitials).(currVisit));
        
        % Dates (e.g. if there are multiple V3's etc.)
        for iDates = 1:length(indDates);
            currDate = indDates{iDates};
            indOpticalOrExercise = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate));
            
            % Include studies only if there is Bike data
            if any(strncmp(indOpticalOrExercise,'Bike',4)) == 1
                
                % Normalize ramp time to itself
                normRamptime = ExeDOSI.(currInitials).(currVisit).(currDate).Bike.Raw.time - ...
                               ExeDOSI.(currInitials).(currVisit).(currDate).Bike.Raw.time(1);
                
                % Optical or Exercise data
                for iOpticalOrExercise = 1:length(indOpticalOrExercise);
                    currOpticalOrExercise = indOpticalOrExercise{iOpticalOrExercise};
                    
                    % Focus on Brain data
                    if any(strncmp(currOpticalOrExercise,'Brain',5)) == 1
                        
                        % FAD/FAC data
                        indFADorFAC = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw);
                        for iFADorFAC = 1:length(indFADorFAC)
                            currFADorFAC = indFADorFAC{iFADorFAC};
                            
                            % Variables for SLM
                            indSLMvars = fieldnames(ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures);
                            for iSLMvars = 1:length(indSLMvars)
                                currSLMvar = indSLMvars{iSLMvars};
                                
                                % Loop for each breakpoint to get eq WR
                                knotWorkRate = zeros(length(ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures.(currSLMvar)));
                                knotRelativeTotalTime = zeros(length(knotWorkRate));
                                for iKnot = 1:length(ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures.(currSLMvar).knots)
                                    currKnot = ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures.(currSLMvar).knots(iKnot);
                                    
                                    % Get exercise data time that is closest to current knot
                                    [~,b] = min(abs(currKnot - ExeDOSI.(currInitials).(currVisit).(currDate).Bike.Raw.time));
                                    
                                    % Get equivalent workrate 
                                    knotWorkRate(iKnot) = ExeDOSI.(currInitials).(currVisit).(currDate).Bike.Raw.W(b);
                                    
                                    % Get relative time of knot over total study time
                                    knotRelativeTotalTime(iKnot) = currKnot/ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).StudyPhases.Ramp.time(end);
                                end
                                
                                % Save equilvalent work rate to superstruct
                                ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures.(currSLMvar).knotWorkRate = knotWorkRate;
                                ExeDOSI.(currInitials).(currVisit).(currDate).Brain.Raw.(currFADorFAC).SLMFigures.(currSLMvar).knotRelativeTotalTime = knotRelativeTotalTime;
                            end
                        end

                    % if present, compare data
                    % loop for both FAD and FAC
                    end


                end
            end
        end
    end
end
disp('done!')
%% Cleanup
clearvars -except ExeDOSI...
                  FileLoopErr...
                  studyPhases
