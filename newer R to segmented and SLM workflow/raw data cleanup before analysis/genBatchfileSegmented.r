## Clean up

#############################################################################
## Generate batch file from current csv format data files
# Example: "generateBatch("PFC")"
# looks for all processed csv files with PFC
generateBatchSeg <- function(keywords,fileName){
	# Locate all applicable files for threshold analysis
	csv	<- dir(pattern="*.csv")

	# Locate optical data by keyword
	csvData		<- csv[grepl("R",csv)] # Processed identifier
	csvData		<- csvData[grepl("Ramp",csvData)] # Ramp identifier
	csvData		<- csvData[grepl(keywords,csvData)] # Additional identifiers

	# Temporary data-table
	default <- vector(mode = "numeric",length = (length(csvData)))
	table   <- data.frame(File=csvData, SpecifSegmentedBPs=default,
						FirstGuess=default, SecondGuess=default)

	# Write batch input table in csv format in separate folder
	dir.create("batch files", showWarnings = FALSE)
	write.table(table,file.path(getwd(),"batch files",paste(fileName,".csv",sep="")),append=FALSE,row.names=FALSE,sep=",")

}

# Test code #
test <- FALSE
if(test){
  generateBatchSeg("PFC|VL|Muscle|Brian","segmented input batch file")
}
