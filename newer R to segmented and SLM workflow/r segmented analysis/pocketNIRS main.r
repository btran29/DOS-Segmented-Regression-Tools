# BT_Lr 12-6-15 Brian
# Main Method for data analysis


# Input
hasExeData = FALSE
keyWords = "bins"  # e.g. "PFC|VL|Muscle|Brain"
seg.it = 10


# Load required packages
library(segmented)


# Source functions for piecewise-linear regression analysis of DOS data
# Assumes scripts are in the working directory. Manually source if need be
source('exeEquivCSV.r') # Includes exeEquivCSV
source('dosSegmented.r') # Includes DOSI.segmented, linearize
source('collectBPdata.r') # Includes collectBPdata, bpFigures
source('collectExeData.r') # Includes collectExeData, writeExeData


# Organizing output into folders via labels (use for later output)
breakpointDataFolder		<- "breakpoint data"
percentExerciseDataFolder	<- "percent exercise data"
segmentedFiguresFolder		<- "segmented figures"


# Get working directory
workingDir <- getwd()


# List studies of interest
dosStudies	<- dir(pattern="*.csv")


# Obtain study-specific breakpoint guess inputs for segmented function
table <- read.csv(file.path(workingDir,"batch files","segmentedBatchFile.csv"))


# Create subdirectories
dir.create(percentExerciseDataFolder, showWarnings=FALSE)
dir.create(breakpointDataFolder, showWarnings=FALSE)
dir.create(segmentedFiguresFolder,showWarnings=FALSE)


# Make a subdirectory for each variable, for both figures and BP data
varList <- c("BR_L","BO_L","BR_R","BO_R","BT_L","BT_R")
createSubDirs <- function(vars,subfolder){
  for(var in 1:length(vars)){
    dir.create(file.path(workingDir,subfolder,vars[var]),showWarnings=FALSE)
  }
}
createSubDirs(varList,breakpointDataFolder)
createSubDirs(varList,segmentedFiguresFolder)


# Loop for each optical data file #
for(study in 1:length(dosStudies)){

  preBreakPoint = TRUE
if(preBreakPoint){
	# Filename for output
	outputFileName	<- gsub(".csv", "", dosStudies[study])


	if(hasExeData){
	# Locate equivalent exercise study
	equivExeStudy	<- exeEquivCSV(dosStudies[study],csv,
					locEXO=1,locVisit=3,locDate=4)
	}


	# Read csv files into data tables
	dosData	<-	read.csv(dosStudies[study])


	if(hasExeData){
	exeData	<-	read.csv(csv[equivExeStudy])
	}


	# Assign data in files to data frames #


	# Assign DOS or EXE-specific time axes, normalizing DOS to begin at 0
	Time     <- dosData$NT
	normTime <- Time-min(Time)

	if(hasExeData){
	exeTime  <- exeData$time
	}

	# Make data frames from variables of interest
	BR_R  <- data.frame(x=normTime, y=dosData$BR_R)
	BR_L   <- data.frame(x=normTime, y=dosData$BR_L)
	BO_R   <- data.frame(x=normTime, y=dosData$BO_R)
	BO_L  <- data.frame(x=normTime, y=dosData$BO_L)
	BT_L <- data.frame(x=normTime, y=dosData$BT_L)
	BT_L <- data.frame(x=normTime, y=dosData$BT_L)

	if(hasExeData){

	  PO  <- data.frame(x=exeTime, y=exeData$PO)
	  PC  <- data.frame(x=exeTime, y=exeData$PC)
	  VO  <- data.frame(x=exeTime, y=exeData$VO2)
	  VOK <- data.frame(x=exeTime, y=exeData$VOK)
	  VC  <- data.frame(x=exeTime, y=exeData$VCO2)
	  BT_L  <- data.frame(x=exeTime, y=exeData$BT_L)
	  HR  <- data.frame(x=exeTime, y=exeData$HR)
	  RR  <- data.frame(x=exeTime, y=exeData$RR)
	  RPM <- data.frame(x=exeTime, y=exeData$RPM)
	  W   <- data.frame(x=exeTime, y=exeData$Work)
	}


	# Convert data to linear models (without any transformations),
	# using a dos or exe-specific time axis
# 	lin	<- list(
# 	  "BR_R"  = lm.BO  <- lm(y~x,data=BR_R),
# 	  "BR_L"  = lm.BR  <- lm(y~x,data=BR_L),
# 	  "BO_R"  = lm.BT  <- lm(y~x,data=BO_R),
# 	  "BO_L"  = lm.BS  <- lm(y~x,data=BO_L)
# 	)

	lin <- list(
	  "BR_L"  = lm.BR  <- lm(y~x,data=BR_L),
	  "BR_R"  = lm.BO  <- lm(y~x,data=BR_R)
	)

	if(hasExeData){
	  lm.EXEdata <- list(
	    "BT_LO" = lm.BT_LO <- lm(y~x,data=BT_LO),
	    "BT_LC" = lm.VC  <- lm(y~x,data=BT_LC),
	    "PO"  = lm.PO  <- lm(y~x,data=PO),
	    "PC"  = lm.PC  <- lm(y~x,data=PC),
	    "VO"  = lm.VO  <- lm(y~x,data=VO),
	    "VC"  = lm.VC  <- lm(y~x,data=VC),
	    "BT_L"  = lm.BT_L  <- lm(y~x,data=BT_L),
	    "HR"  = lm.HR  <- lm(y~x,data=HR),
	    "RR"  = lm.RR  <- lm(y~x,data=RR),
	    "RPM" = lm.RPM <- lm(y~x,data=RPM)
	  )
	}

	# Combine to run segmented
	if(hasExeData){
		lin <- c(lin,lm.EXEdata)
	}


	# Run segmented #

	# Obtain breakpoints input for segmented function - just BR_L for now
	segmentedMethod	<- table$SpecifSegmentedBPs[study]
	segmentedBP1	<- table$FirstGuess[study]
	segmentedBP2	<- table$SecondGuess[study]
}

	# Run segmented
	bpOutput	<- sapply(lin,DOSI.segmented,
				segmentedMethod,segmentedBP1,segmentedBP2,
				simplify=FALSE,USE.NAMES=TRUE)

postBreakPoint = TRUE
if(postBreakPoint){
	# Compare BP data with exe data
	if(hasExeData){

  	# Set span over which to mean exercise data for each breakpoint
  	span = (5/60) # Mean +/- 5 seconds, assuming data in minutes


  	# Output BP data using span and collectBPdata function
  	bpOutput2<-sapply(bpOutput,collectBPdata,span,simplify=FALSE,USE.NAMES=TRUE)


  	# Collect and output exercise data
  	exeDataFileName <- file.path(workingDir,percentExerciseDataFolder,outputFileName)
  	writeExeData(collectExeData(0,span=0),"MinWR",exeDataFileName)
  	writeExeData(collectExeData(0.2,span=0),"E20",exeDataFileName)
  	writeExeData(collectExeData(0.4,span=0),"E40",exeDataFileName)
  	writeExeData(collectExeData(0.6,span=0),"E60",exeDataFileName)
  	writeExeData(collectExeData(0.8,span=0),"E80",exeDataFileName)
  	writeExeData(collectExeData(1,span=0),"MaxWR",exeDataFileName)

	} else {

      # If hasExeData is set to false, just run collectBPdata with out exe data functions
		  bpOutput2 <-sapply(bpOutput,collectBPdata,span,hasExeData=FALSE,simplify=FALSE,USE.NAMES=TRUE)
	}


	# Write segmented data into a csv file
	writeBPdata <- function(label,data){
	  bpFileName <- file.path(workingDir,breakpointDataFolder,label,outputFileName)
	  bpFileName <- paste(bpFileName," ",label," BP.csv",sep="")
	  write.csv(data,file=bpFileName,row.names=FALSE)
	}

	writeBPdata("BR_L",bpOutput2$BR_L)
# 	writeBPdata("BO_L",bpOutput2$BO_L)
# 	writeBPdata("BR_R",bpOutput2$BR_R)
# 	writeBPdata("BO_R",bpOutput2$BO_R)
#
# 	if(hasExeData){ # write exercise data if present
# 	  writeBPdata("BT_L",bpOutput2$BT_L)
# 	  writeBPdata("PC",bpOutput2$PC)
# 	}


	# Figures #

	tiffoutput <- function(VarName){
	    fileName <- file.path(workingDir,segmentedFiguresFolder,VarName,paste(VarName,outputFileName,"Figure.tiff",sep=" "))
		  tiff(fileName, units = "px", width = 600, height = 600, res = NA, compression = "lzw")
	}

	# Plot figures - Used try statements as some data is known to be too
	# noisy to all have breakpoints or successful

	tiffoutput("BR_L")
	try({bpFigures(bpOutput$BR_L,"Time (min)","[BR_L] (uM)","PFC BR_L")})
	dev.off()
}
# 	tiffoutput("BO_L")
# 	try({bpFigures(bpOutput$BO_L,"Time (min)","BO_L (uM)","PFC BO_L")})
# 	dev.off()
#
# 	tiffoutput("BR_R")
# 	try({bpFigures(bpOutput$BR_R,"Time (min)","BR_R (uM)","PFC BR_R")})
# 	dev.off()
#
# 	tiffoutput("BO_R")
# 	try({bpFigures(bpOutput$BO_R,"Time (min)","BO_R (uM)","PFC BO_R")})
# 	dev.off()
#
# 	if(hasExeData){ # Output exercise data if present
# 	  tiffoutput("BT_L")
# 		try({bpFigures(bpOutput$BT_L,"Time (min)","BT_L (L/min)","BT_L")})
# 	  dev.off()
#
# 	  tiffoutput("BT_R")
# 		try({bpFigures(bpOutput$PC,"Time (min)","BT_R mmHg","BT_R")})
# 	  dev.off()
# 	}


	# Remove data for each study after output to tables and figures to prevent writing
	# previous study's data to the next study
	remove(bpOutput)
	remove(bpOutput2)
}
