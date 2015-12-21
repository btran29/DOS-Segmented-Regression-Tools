outputBlock <- function(keywords, column, label){
# Output transposed block of a column of data from studies w/ keywords
# This script selects a column of data from all studies in a 
# working directory, then outputs it all in a single copy-
# paste-able block in a workbook named after the first search term.
	
	# Usage 
	if (exists(keywords,mode="any")   == FALSE ||
		exists(column,mode="numeric") == FALSE ||
		exists(label,mode="string")   == FALSE ||
		) {
		warning("To use: outputBlock(keywords, column, label), where 
				keywords can be a string or a list of strings,
				columns must be a valid column the data files, and
				label must be a string that can be appended to the
				summary sheet file name. \n
				Example: outputBlock(c("PFC","Brain"),2,bpEstY)
				")
		# Stop function
		stop
		}
		
	# List directory
	fileType = dir(pattern="*.csv")
	
	keywords = list(keywords)
	
	# List files with keywords in filename
	files = grepl(keywords[1],fileType)
	
	# Recurse grepl through list if using multiple keywords
	if(length(keywords)>=2){
		for(keyword in 2:length(keywords)){
			files = grepl(keywords[keyword],files)
		}
	}
	
	# Stop function if no files were found
	if(length(keywords) <1){
		warning("No selected filetype with keyword(s) found")
		stop
	}
	
	# Collect data from files of interest
	data = array(NaN, dim=c(length(files),5000))
	for(file in 1:length(files)){
		table = read.table(files(file))
		data[1,1:length(table[,column])]  = table[,column]
	} # TODO: first pass scan to get max data size,
	  #	replace magic '5000'
	
	# Clean up array by removing NaNs
	data = apply(data, 1, function(x) x[!is.nan(x)]) 
	
	# Write data into a named csv file
	fileName = paste("summary",keyword[1],label)
	write.csv(data,file=fileName,row.names=FALSE)
	
}
