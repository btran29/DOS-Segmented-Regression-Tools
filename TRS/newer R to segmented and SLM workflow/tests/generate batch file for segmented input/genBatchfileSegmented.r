## Clean up

#############################################################################
## Generate batch file from current csv format data files
# Example: "generateBatch("PFC")"
# looks for all processed csv files with PFC
generateBatch <- function(argv){
	# Locate all applicable files for threshold analysis
	csv	<- dir(pattern="*.csv")

	# Locate optical data by keyword
	csvData		<- csv[grepl("Processed",csv)]
	csvData		<- csvData[grepl(argv,csvData)]

	# Temporary data-table
	default <- vector(mode = "numeric",length = (length(csvData)))
	table   <- data.frame(File=csvData, SpecifSegmentedBPs=default,
						FirstGuess=default, SecondGuess=default)

	# Write batch input table in tsv format
	write.table(table,"study phase markers batch file.txt",append=FALSE,row.names=FALSE,sep="\t")

}

generateBatch("PFC")
