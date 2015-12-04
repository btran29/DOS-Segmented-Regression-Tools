# Function to locate equivalent exercise
# 	Given an input of study name:
#		Split it by spaces, then compare with other studies in the file-list
#		until EXE study with same EXO, date, & visit is found
#		Meant to be used in relation to an index of optical data
#	Output: index of exercise study
exeEquivCSV <- function(argv){
	split	<- strsplit(argv," ")
	exo		<- split[[1]][1]
	visit	<- split[[1]][3]
	date	<- split[[1]][4]

	# E.g. EXO-1 AaAa V5 12-1-15 EXE
	pattern <- paste(exo,"+ \\w+ ",visit,
				"+ \\d\\d-\\d\\d-\\d\\d",
				"+ EXE",sep="")
	indExe	<- grep(pattern,csv)
	return(indExe)
}


# Test code #

# Generate pre-reqs
csv		<- dir(pattern="*csv")
csvData	<- csv[grep("PFC",csv)]

# Run function
exeEquivCSV(csvData[1]) # Should equal 1
exeEquivCSV(csvData[2]) # Should equal 4
exeEquivCSV(csvData[3]) # Should equal 6
