# Function to locate equivalent exercise
# 	Given an input of study name:
#		Split it by spaces, then compare with other studies in the file-list
#		until EXE study with same EXO, date, & visit is found
#		Meant to be used in relation to an index of optical data
#	Output: index of exercise study in relation to total csv
exeEquivCSV <- function(studyName,dirlist,locEXO,locVisit,locDate){
	# Split study name by space
	split	<- strsplit(studyName," ")
	exo		<- split[[1]][locEXO]
	visit	<- split[[1]][locVisit]
	date	<- split[[1]][locDate]

	# E.g. EXO-1 AaAa V5 12-1-15 EXE
	pattern <- paste(exo,"+ \\w+ ",visit,
				"+ \\d\\d-\\d\\d-\\d\\d",
				"+ EXE",sep="")
	indExe	<- grep(pattern,dirlist)
	return(indExe)
}


# Test code #
test <- FALSE
if(test){
	# Generate pre-reqs
	csv		<- dir(pattern="*csv")
	csvData	<- csv[grep("PFC",csv)]

	# Run function
	exeEquivCSV(csvData[1],csv,locEXO=1,locVisit=3,locDate=4) # Should equal 1
	exeEquivCSV(csvData[2],csv,locEXO=1,locVisit=3,locDate=4) # Should equal 4
	exeEquivCSV(csvData[3],csv,locEXO=1,locVisit=3,locDate=4) # Should equal 6
}
