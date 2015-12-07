# Function to split DOS data from the TRS by study phases
# Given a working directory + a specified batch file with markers
# denoting study phases:
#	Read the batch file,
#	Locate 1st index of each study phase
#	Split data into separate study phase files for later analysis
# E.g. splitByMarker("PFC|VL|Muscle|Brian",'batch files/study phase markers batch file.csv')
# Function returns: none

splitByMarker <- function(keywords,batchFileDir,batchFile){

	# Read table
  setwd(batchFileDir)
	table <- read.table(batchFile, header=TRUE)
  setwd("..")

	# Locate all applicable files for threshold analysis
	csv	<- dir(pattern="*.csv")

	# Locate optical data by keyword
	csvData	<- csv[grepl(keywords,csv)]

	# Folder output
	dir.create("Data split by study phase")
	dir.create("Data split by study phase - binned")

	# Locate index of ea. study for each file
	for(file in 1:length(csvData)){
		rampBeg	<-	table[[2]][file]
		rampEnd	<-	table[[3]][file]
		pedBeg	<-	table[[4]][file]
		recovBeg<-	table[[5]][file]
		pedEnd	<-	table[[6]][file]


		# Load file, assumes CSV with a column called 'Marker'
		data <- read.csv(csv[file])
		indRampBeg	<-	which(data$Marker==rampBeg)
		indRampEnd	<-	which(data$Marker==rampEnd)
		indPedBeg	<-	which(data$Marker==pedBeg)
		indRecovBeg	<-	which(data$Marker==recovBeg)
		indPedEnd	<-	which(data$Marker==pedEnd)


		# Rearrange columns to match previous 15-column format,
		# assuming original TRS column-labels are kept
		reorganized <-	data.frame(data$HbO2,data$Hb,data$tHb,data$SO2,
						data$ElapsTime,data$Marker,data$SC1,data$SC2,
						data$SC3,data$AC1,data$AC2,data$AC3,data$PL1,
						data$PL2,data$PL3)


		# Define phases via marker data
		allphases	<-	reorganized
		baseline	<-	reorganized[1:(indRampBeg-1),]
		ramp		<-	reorganized[indRampBeg:(indRampEnd-1),]
		recovery	<-	reorganized[indRampEnd:(length(data[,1])),]


		# Bin Data
		binSizes = 10/60 # 10 seconds over data in minutes

		allphases.binned	<-	data.frame(sapply(allphases,uneqBinMeans,
							binSize=binSizes,timeAxis=allphases$ElapsTime))
		baseline.binned		<-	data.frame(sapply(baseline,uneqBinMeans,
							binSize=binSizes,timeAxis=baseline$ElapsTime))
		ramp.binned			<-	data.frame(sapply(ramp,uneqBinMeans,
							binSize=binSizes,timeAxis=ramp$ElapsTime))
		recovery.binned		<-	data.frame(sapply(recovery,uneqBinMeans,
							binSize=binSizes,timeAxis=recovery$ElapsTime))


		# Generate meaningful time axis for binned data
		allphases.binned$ElapsTime <- seq(from=allphases.binned$ElapsTime[1],
										  to=allphases.binned$ElapsTime[length(allphases.binned$ElapsTime)],
										  by=10)
		baseline.binned$ElapsTime <- seq(from=baseline.binned$ElapsTime[1],
										  to=baseline.binned$ElapsTime[length(baseline.binned$ElapsTime)],
										  by=10)
		ramp.binned$ElapsTime <- seq(from=ramp.binned$ElapsTime[1],
										  to=ramp.binned$ElapsTime[length(ramp.binned$ElapsTime)],
										  by=10)
		recovery.binned$ElapsTime <- seq(from=recovery.binned$ElapsTime[1],
										  to=recovery.binned$ElapsTime[length(recovery.binned$ElapsTime)],
										  by=10)


		# Get current file for output file name
		outputFileName	<- paste(gsub(".csv","",csvData[file]),"Processed",sep=" ")


		# Output unbinned data
		setwd("Data split by study phase")
		write.table(allphases,paste(outputFileName," All Phases",".csv",sep=""),
		append=FALSE,row.names=FALSE,sep=",")
		write.table(baseline,paste(outputFileName," Baseline",".csv",sep=""),
		append=FALSE,row.names=FALSE,sep=",")
		write.table(ramp,paste(outputFileName," Ramp",".csv",sep=""),
		append=FALSE,row.names=FALSE,sep=",")
		write.table(recovery,paste(outputFileName," Recovery",".csv",sep=""),
		append=FALSE,row.names=FALSE,sep=",")
		setwd("..")


		# Output binned data
		setwd("Data split by study phase")
		write.table(allphases.binned,paste(outputFileName," All Phases - Binned",
		".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
		write.table(baseline.binned,paste(outputFileName," Baseline - Binned",
		".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
		write.table(ramp.binned,paste(outputFileName," Ramp - Binned",
		".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
		write.table(recovery.binned,paste(outputFileName," Recovery - Binned",
		".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
		setwd("..")
	}


}

# Testing code #
test <- FALSE
if(test){
# Should ouput 8 csv files with listed names, include studies with stated
# keywords, and have fewer rows in the binned versions (check bins)
splitByMarker("PFC|VL|Muscle|Brain",'study phase markers batch file.csv')
}
