# Ver 12-6-15 Brian
# Main Method for data analysis

# Load required packages
library(segmented)


# Source functions for piecewise-linear regression analysis of DOS data
source('exeEquivCSV.r') # Includes exeEquivCSV
source('dosSegmented.r') # Includes DOSI.segmented, linearize
source('collectBPdata.r') # Includes collectBPdata, writeBPData, bpFigures 
source('collectExeData.r') # Includes collectExeData, writeExeData


# Organizing output into folders via labels (use for later output)
breakpointDataFolder		<- "breakpoint data"
percentExerciseDataFolder	<- "percent exercise data"
segmentedFiguresFolder		<- "segmented figures"
dir.create(breakpointDataFolder, showWarnings=FALSE)
dir.create(percentExerciseDataFolder, showWarnings=FALSE)
dir.create(segmentedFiguresFolder,showWarnings=FALSE)


# List studies of interest
csv			<- dir(pattern="*csv")
dosStudies	<- csv[grep("PFC|VL|Muscle|Brain",csv)]


# Obtain study-specific breakpoint guess inputs for segmented function
setwd("batch files")
	table <- read.csv("study phase markers batch file.csv")
setwd("..")


# Loop for each optical data file
for(study in 1:length(dosStudies)){

	# Filename for output
	outputFileName	<- dosStudies[study]
	
	
	# Locate equivalent exercise study
	equivExeStudy	<- exeEquivCSV(dosStudies[study],csv,
					locEXO=1,locVisit=3,locDate=4)	
	

	# Read csv files into data tables
	dosData	<-	read.csv(dosStudies[study])
	exeData	<-	read.csv(csv[equivExeStudy])
	
	
	# Assign data in files to data frames #
	
	
	# Assign DOS or EXE-specific time axes, normalizing DOS to begin at 0
	Time     <- dosData$time
	normTime <- Time-min(Time)
	exeTime  <- exeData$time

	
	# Make data frames from variables of interest
	varDosData	<-	data.frame(dosData$HbO2,
								dosData$HbR,
								dosData$THb,
								dosData$stO2)
	varExeData <-	data.frame(exeData$VEO,
								exeData$VEC,
								exeData$PO,
								exeData$PC,
								exeData$VO2,
								exeData$VCO2,
								exeData$VE,
								exeData$HR,
								exeData$RR,
								exeData$Work)
	
	
	# Conver data to linear models (without any transformations), 
	# using a dos or exe-specific time axis
	lm.DOSdata	<- sapply(varDosData,linearize,xaxis=normTime,
					simplify=FALSE,USE.NAMES = TRUE)
	lm.EXEdata	<- sapply(varExeData,linearize,xaxis=exeTime,
					simplify=FALSE,USE.NAMES = TRUE)
	
	
	# Combine to run segmented
	lin <- c(lm.DOSdata,lm.EXEdata)
		
		
	# Run segmented #
	
	
	# Obtain breakpoints input for segmented function
	segmentedMethod	<- table$SpecifSegmentedBPs[study]
	segmentedBP1	<- table$FirstGuess[study]
	segmentedBP2	<- table$SecondGuess[study]
	
	# Run segmented
	bpOutput	<- sapply(lin,DOSI.segmented,
				segmentedMethod,segmentedBP1,segmentedBP2,
				simplify=FALSE,USE.NAMES=TRUE)
		
		
	# Collect and output BP data
	
	
	# Set span over which to mean exercise data for each breakpoint
	span = (5/60) # Mean +/- 5 seconds, assuming data in minutes
	
	
	# Output BP data using span and collectBPdata function
	bpOutput2<-sapply(bpOutput,collectBPdata,span,simplify=FALSE,USE.NAMES=TRUE)
	
	
	# Write segmented data into a csv file
	setwd(breakpointDataFolder)
		writeBPdata(bpOutput,bpOutput2,outputFileName)
	setwd("..")
	
	
	# Collect and output exercise data
	setwd(percentExerciseDataFolder)
		writeExeData(collectExeData(0,span=0),"MinWR",outputFileName)
		writeExeData(collectExeData(0.2,span=0),"E20",outputFileName)
		writeExeData(collectExeData(0.4,span=0),"E40",outputFileName)
		writeExeData(collectExeData(0.6,span=0),"E60",outputFileName)
		writeExeData(collectExeData(0.8,span=0),"E80",outputFileName)
		writeExeData(collectExeData(1,span=0),"MaxWR",outputFileName)
	setwd("..")
		
		
	# Figures #

	# Plot figures - Used try statements as some data is known to be too 
	# noisy to all have breakpoints or successful
	setwd(segmentedFiguresFolder)
		pdf(paste(outputFileName," Figures.pdf",sep=""))
		try({bpFigures(bpOutput$HbR,"Time (min)","[HbR] (uM)","PFC HbR")})
		try({bpFigures(bpOutput$stO2,"Time (min)","stO2 (uM)","PFC stO2")})
		try({bpFigures(bpOutput$HbO2,"Time (min)","HbO2 (uM)","PFC HbO2")})
		try({bpFigures(bpOutput$THb,"Time (min)","THb (uM)","PFC THb")})
		try({bpFigures(bpOutput$VE,"Time (min)","VE (L/min)","VE")})
		try({bpFigures(bpOutput$PC,"Time (min)","PETCO2 mmHg","PETCO2")})
		dev.off()
	setwd("..")
}
