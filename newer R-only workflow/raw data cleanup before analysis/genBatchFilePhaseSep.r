## Clean up

#############################################################################
## Generate batch file from current csv format data files
# Example: "generateBatch("PFC")"
# looks for all processed csv files with PFC
generateBatchPhase <- function(keywords,fileName){
	# Locate all applicable files for threshold analysis
	csv	<- dir(pattern="*.csv")

	# Locate optical data by keyword
	csvData		<- csv[grepl(keywords,csv)]

	# Temporary data-table
	default <- vector(mode = "numeric",length = (length(csvData)))
	table   <- data.frame(File=csvData, rampBeg=default,
						rampEnd=default, pedBeg=default,
						recovBeg=default, pedEnd=default)

	# Write batch input table in csv format in new folder
	dir.create("batch files",showWarnings = FALSE)
	setwd("batch files")
	write.table(table,paste(fileName,".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
	setwd("..")

}

# Test code #
test <- FALSE
if(test){
# Should only include studies with keywords, and tab-delineated text file
# output should be named as stated in command below.
  generateBatchPhase("PFC|VL|Muscle|Brian","study phase markers batch file")
}
