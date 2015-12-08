## Function to bin data (unequal bin sizes) in R
# Given an input of bin size, time axis data, and variable
# data:
#	Generate bins of stated bin size,
#	Cut the data into the bins,
#	Obtain the means of each of the bins
# Output: bin means array

uneqBinMeans	<- function(data,binSize,timeAxis){

	# Generate linearlay spaced intervals for binning
	binEdges	<- seq(from=timeAxis[1],to=(timeAxis[length(timeAxis)]+binSize),by=binSize)

	# Initialize binMeans vector
	binMeans <- vector()

	for(iBinEdge in 1:length(binEdges)){

	  # Initialize/reset flags
	  flagforbin = logical(length(timeAxis))

	  # Flag data that fits into current bin
	  allIdx = 1:length(timeAxis)
	  idx = allIdx[timeAxis>=binEdges[iBinEdge] & timeAxis<=binEdges[iBinEdge+1]]
	  flagforbin[idx] = TRUE

	  # Assign data to bin and mean
	  binMeans[iBinEdge] = mean(data[flagforbin])
	}

	# Remove NaN values
	binMeans <- binMeans[complete.cases(binMeans)]

	# Output array of means
	return(binMeans)
}

# Test code #
test <- FALSE
if(test){
  # Read data in test folder
  dosdata <- read.csv("test.csv")
  exedata <- read.csv("exeSample.csv")

  # Output individual columns
  uneqBinMeans(10/60,dosdata$ElapsTime,dosdata$HbO2)
  uneqBinMeans(10/60,exedata$time,exedata$HR)

  # Output entire table
  testOut <- data.frame(sapply,exedata,uneqBinMeans,binSize=10/60,timeAxis=exedata$time)
}
