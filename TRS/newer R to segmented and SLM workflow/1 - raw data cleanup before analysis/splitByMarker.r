# Function to split DOS data from the TRS by study phases
# Given a working directory + a specified batch file with markers
# denoting study phases:
#	Read the batch file,
#	Locate 1st index of each study phase
#	Split data into separate study phase files for later analysis
# E.g. splitByMarker("PFC|VL|Muscle|Brian",'batch files/study phase markers batch file.csv')
# Function returns: none

source('unequalBinMeans.r') # Includes uneqBinMeans

splitByMarker <- function(keywords,batchFileDir,batchFile,binSizes){

  # Get current working directory
  workingDir <- getwd()

  # Read table
  table <- read.csv(file.path(workingDir,batchFileDir,batchFile),header=TRUE)

  # Locate all applicable files for threshold analysis
  csv	<- dir(pattern="*.csv")

  # Locate optical data by keyword
  csvData	<- csv[grepl(keywords,csv)]

  # Folder output
  splitFolderName1 <- "Data split by study phase"
  splitFolderName2 <- "Data split by study phase - binned"
  dir.create(splitFolderName1)
  dir.create(splitFolderName2)

  # Locate index of ea. study for each file
  for(file in 1:length(csvData)){
    rampBeg	<-	table[[2]][file]
    rampEnd	<-	table[[3]][file]
    pedBeg	<-	table[[4]][file]
    recovBeg<-	table[[5]][file]
    pedEnd	<-	table[[6]][file]


    # Load file, assumes CSV with a column called 'Marker'
    data <- read.csv(csv[file])
    indRampBeg	<-	which(data$Marker==rampBeg)[1] #First val only
    indRampEnd	<-	which(data$Marker==rampEnd)[1] # if duplicate
    indPedBeg	  <-	which(data$Marker==pedBeg)[1]
    indRecovBeg	<-	which(data$Marker==recovBeg)[1]
    indPedEnd	  <-	which(data$Marker==pedEnd)[1]


    # Rearrange columns to match previous 14-column format,
    # assuming original TRS column-labels are kept
    reorganized <-	data.frame(data$ElapsTime,data$HbO2,
                              data$Hb,data$tHb,data$SO2,
                              data$SC1,data$SC2,data$SC3,
                              data$AC1,data$AC2,data$AC3,
                              data$PL1,data$PL2,data$PL3)

    # Clean up column names
    headers <- colnames(reorganized)
    headers <- gsub("data.", "", headers)
    colnames(reorganized) <- headers



    # Define phases via marker data
    allphases	<-	reorganized
    baseline	<-	reorganized[1:(indRampBeg[1]-1),]
    ramp		<-	reorganized[indRampBeg[1]:(indRampEnd[1]-1),]
    recovery	<-	reorganized[indRampEnd[1]:(length(data[,1])),]

	
	# Function to get relative time to beginning of phase, add to the table as column second 
	# to ElapsTime
	phaseTime <- function(phaseTimeData){
	
		# Get first time point
		phaseTimeData[1] <- firstTimePoint
		
		# Create collection vector
		phaseTime <- vector(mode="numeric", length=length(phaseTimeData))
		
		for(iRow in 1:length(phaseTimeData)){
			phaseTime[iRow] <- phaseTimeData[iRow] - firstTimePoint
		}
	}
	
	
	# Incorporate relative phase time to each phase's data
	allphases.phasetime <- phaseTime(allphases$ElapsTime)
	allphases <- rbind(allphases,allphases.phasetime)
	
	baseline.phasetime <- phaseTime(baseline$ElapsTime)
	baseline <- rbind(baseline,baseline.phasetime)
	
	ramp.phasetime <- phaseTime(ramp$ElapsTime)
	ramp <- rbind(ramp,ramp.phasetime)
	
	recovery.phasetime <- phaseTime(recovery$ElapsTime)
	recovery <- rbind(recovery,recovery.phasetime)
	
	
    # Bin Data
    # binSizes = 10/60 # 10 seconds over data in minutes

    allphases.binned	<-	data.frame(sapply(allphases,uneqBinMeans,
                                          binSize=binSizes,timeAxis=allphases$ElapsTime))
    baseline.binned		<-	data.frame(sapply(baseline,uneqBinMeans,
                                          binSize=binSizes,timeAxis=baseline$ElapsTime))
    ramp.binned			<-	data.frame(sapply(ramp,uneqBinMeans,
                                       binSize=binSizes,timeAxis=ramp$ElapsTime))
    recovery.binned		<-	data.frame(sapply(recovery,uneqBinMeans,
                                          binSize=binSizes,timeAxis=recovery$ElapsTime))


    # Generate meaningful time axis for binned data

    # New vars for code clarity
    al <- allphases.binned$ElapsTime
    ba <- baseline.binned$ElapsTime
    ra <- ramp.binned$ElapsTime
    re <- recovery.binned$ElapsTime

    allphases.binned$ElapsTime <- seq(from=0,to=(length(al)*10)+10,
                                      by=10)[1:length(al)]

    baseline.binned$ElapsTime <- seq(from=0,to=(length(ba)*10)+10,
                                     by=10)[1:length(ba)]

    ramp.binned$ElapsTime <- seq(from=0,to=(length(ra)*10)+10,
                                 by=10)[1:length(ra)]

    recovery.binned$ElapsTime <- seq(from=0,to=(length(re)*10)+10,
                                     by=10)[1:length(re)]


    # Get current file for output file name
    outputFileName	<- paste(gsub(".csv","",csvData[file]),"R",sep=" ")


    # Output unbinned data #

    # Folder output
    dir.create(file.path(workingDir,splitFolderName1,"All Phases"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName1,"Baseline"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName1,"Ramp"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName1,"Recovery"),showWarnings = FALSE)

    # Table output


    write.table(allphases,
                file=file.path(workingDir,splitFolderName1,"All Phases",
                               paste(outputFileName," All Phases",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(baseline,
                file=file.path(workingDir,splitFolderName1,"Baseline",
                               paste(outputFileName," Baseline",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(ramp,
                file=file.path(workingDir,splitFolderName1,"Ramp",
                               paste(outputFileName," Ramp",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(recovery,
                file=file.path(workingDir,splitFolderName1,"Recovery",
                               paste(outputFileName," Recovery",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")


    # Output binned data #

    # Folder output
    dir.create(file.path(workingDir,splitFolderName2,"All Phases"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName2,"Baseline"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName2,"Ramp"),showWarnings = FALSE)
    dir.create(file.path(workingDir,splitFolderName2,"Recovery"),showWarnings = FALSE)

    # Table output
    write.table(allphases.binned,
                file=file.path(workingDir,splitFolderName2,"All Phases",
                               paste(outputFileName," All Phases",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(baseline.binned,
                file=file.path(workingDir,splitFolderName2,"Baseline",
                               paste(outputFileName," Baseline",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(ramp.binned,
                file=file.path(workingDir,splitFolderName2,"Ramp",
                                            paste(outputFileName," Ramp",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")

    write.table(recovery.binned,
                file=file.path(workingDir,splitFolderName2,"Recovery",
                               paste(outputFileName," Recovery",".csv",sep="")),
                append=FALSE,row.names=FALSE,sep=",")
  } # end iterate over each file


}

# Testing code #
test <- FALSE
if(test){
  # Should ouput 8 csv files with listed names, include studies with stated
  # keywords, and have fewer rows in the binned versions (check bins)
  splitByMarker("PFC|VL|Muscle|Brain",'batch files','study phase markers batch file.csv',10/60)
}
