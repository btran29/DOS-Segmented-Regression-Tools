## Clean up

#############################################################################
## Generate batch file from current csv format data files
# Example: "generateBatch("PFC")"
# looks for all processed csv files with PFC
generateBatchSeg <- function(keywords,fileName){
	# Locate all applicable files for threshold analysis
	csv	<- dir(pattern="*.csv")

	# Locate optical data by keyword
	csvData		<- csv[grepl("Processed",csv)]
	csvData		<- csvData[grepl(keywords,csvData)]

	# Temporary data-table
	default <- vector(mode = "numeric",length = (length(csvData)))
	table   <- data.frame(File=csvData, SpecifSegmentedBPs=default,
						FirstGuess=default, SecondGuess=default)

	# Write batch input table in csv format in separate folder
	dir.create("batch files", showWarnings = FALSE)
	setwd("batch files")
	write.table(table,paste(fileName,".csv",sep=""),append=FALSE,row.names=FALSE,sep=",")
  setwd("..")
}

# Test code #
test <- FALSE
if(test){
  generateBatchSeg("PFC|VL|Muscle|Brian","segmented input batch file")
}
