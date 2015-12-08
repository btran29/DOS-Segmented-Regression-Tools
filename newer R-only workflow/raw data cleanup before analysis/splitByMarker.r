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
	table <- read.csv(batchFile, header=TRUE)
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
		indRampBeg	<-	which(data$Marker==rampBeg)[1] #First val only
		indRampEnd	<-	which(data$Marker==rampEnd)[1] # if duplicate
		indPedBeg	<-	which(data$Marker==pedBeg)[1]
		indRecovBeg	<-	which(data$Marker==recovBeg)[1]
		indPedEnd	<-	which(data$Marker==pedEnd)[1]


		# Rearrange columns to match previous 14-column format,
		# assuming original TRS column-labels are kept
		reorganized <-	data.frame(data$ElapsTime,data$HbO2,
		                          data$Hb,data$tHb,data$SO2,
						                  data$SC1,data$SC2,data$SC3,
						                  data$AC1,data$AC2,data$AC3,
						                  data$PL1,data$PL2,data$PL3)


		# Define phases via marker data
		allphases	<-	reorganized
		baseline	<-	reorganized[1:(indRampBeg[1]-1),]
		ramp		<-	reorganized[indRampBeg[1]:(indRampEnd[1]-1),]
		recovery	<-	reorganized[indRampEnd[1]:(length(data[,1])),]


		# Bin Data
		binSizes = 10/60 # 10 seconds over data in minutes

		allphases.binned	<-	data.frame(sapply(allphases,uneqBinMeans,
							binSize=binSizes,timeAxis=allphases$data.ElapsTime))
		baseline.binned		<-	data.frame(sapply(baseline,uneqBinMeans,
							binSize=binSizes,timeAxis=baseline$data.ElapsTime))
		ramp.binned			<-	data.frame(sapply(ramp,uneqBinMeans,
							binSize=binSizes,timeAxis=ramp$data.ElapsTime))
		recovery.binned		<-	data.frame(sapply(recovery,uneqBinMeans,
							binSize=binSizes,timeAxis=recovery$data.ElapsTime))


		# Generate meaningful time axis for binned data

		# New vars for code clarity
		al <- allphases.binned$data.ElapsTime
		ba <- baseline.binned$data.ElapsTime
		ra <- ramp.binned$data.ElapsTime
		re <- recovery.binned$data.ElapsTime

		allphases.binned$data.ElapsTime <- seq(from=0,to=(length(al)*10)+10,
		                                       by=10)[1:length(al)]

		baseline.binned$data.ElapsTime <- seq(from=0,to=(length(ba)*10)+10,
		                                      by=10)[1:length(ba)]

		ramp.binned$data.ElapsTime <- seq(from=0,to=(length(ra)*10)+10,
		                                  by=10)[1:length(ra)]

		recovery.binned$data.ElapsTime <- seq(from=0,to=(length(re)*10)+10,
		                                      by=10)[1:length(re)]


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
		setwd("Data split by study phase - binned")
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
splitByMarker("PFC|VL|Muscle|Brain",'batch files','study phase markers batch file.csv')
}
