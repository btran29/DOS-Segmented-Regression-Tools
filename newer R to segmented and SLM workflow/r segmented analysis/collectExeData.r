# Function to find data at exercise levels of interest
# Given an input of percentage e.g. (.5 for 50%) of work-rate:
#	locate the equivalent exercise data at that percentage
#	average +/- span for key variables
# Output: average W, VOK, HR, VE + standard deviations
collectExeData <- function(argv,span){

	# Percentage of max work rate
	percentWorkRate = argv*max(W)
	percentExeTime  = argv*max(exeTime)

	# Factor over which to average data
	span = span

	# Subfunction to find index of closest value
	findClosest <- function(value,lookHere){
		ind	<- which(abs((value)-lookHere)==min(abs((value)-lookHere)))
		return(ind)
	}

	if(argv == 1){
	# Case for max W
		equivExeTime       <- tail(W, n=1)[[1]][1]
		indLequivExeTime   <- findClosest((equivExeTime-2*span),exeTime)
		indUequivExeTime   <- which(equivExeTime==exeTime)
	} else if(argv == 0){
	# Case for min W
		equivExeTime       <- head(W, n=1)[[1]][1]
		indLequivExeTime   <- which(equivExeTime==exeTime)
		indUequivExeTime   <- findClosest((equivExeTime+2*span),exeTime)
	} else {
	# Case for all other percentages of W
		equivExeTime		<- exeTime[findClosest(percentExeTime,exeTime)]
		indLequivExeTime	<- findClosest((equivExeTime-span),exeTime)
		indUequivExeTime	<- findClosest((equivExeTime+span),exeTime)

	}

	# Initialize vectors to collect data
	AvgW			    <- vector()
	AvgWstDev     <- vector()
	AvgVOK			  <- vector()
	AvgVOKstDev		<- vector()
	AvgHR			    <- vector()
	AvgHRstDev		<- vector()
	AvgVE			    <- vector()
	AvgVEstDev		<- vector()


	# Collect data +/- factor from timepoint of interest
	AvgW      	<- mean(W$y[indLequivExeTime[1]:indUequivExeTime[1]])
	AvgWstDev 	<- sd(W$y[indLequivExeTime[1]:indUequivExeTime[1]])

	AvgVOK      <- mean(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])
	AvgVOKstDev <- sd(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])

	AvgHR       <- mean(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])
	AvgHRstDev  <- sd(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])

	AvgVE       <- mean(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])
	AvgVEstDev  <- sd(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])


   # Collect data into a dataframe
   perWRdata <- data.frame(# Exercises Variables of interest
						  AvgW,AvgWstDev,
						  AvgVOK,AvgVOKstDev,
						  AvgHR,AvgHRstDev,
						  AvgVE,AvgVEstDev)
	return(perWRdata)
}


# Function to write data
# Given an input of a collectExeData data frame, and a label e.g "Maximum
# work-rate data":
#	Append contents of the data frame onto the output file name
# Output: no direct output, data in csv
writeExeData <- function(argv, label,outputFileName){
    write.table(paste(label,sep=" "),
                paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,
                row.names=FALSE)

    write.table(argv,
                paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,
                row.names=FALSE)
}


# Test Code #
test <- FALSE

if(test){
# Generate pre-requisites
csv	<- dir(pattern="*.csv")
csvExeData <- read.csv(csv[1], header = TRUE)
exeTime	<- csvExeData[[1]]
VOK		<- data.frame(x=exeTime, y=csvExeData[[7]])
VE		<- data.frame(x=exeTime, y=csvExeData[[9]])
HR		<- data.frame(x=exeTime, y=csvExeData[[10]])
W		<- data.frame(x=exeTime, y=csvExeData[[13]])

outputFileName <- "EXO-1 AaAa V3 11-11-11 "

# Call function 1
collectExeData(0) # W should be ~2.8, VOK should be ~8.68, HR should be ~92
collectExeData(0.5) # W should be ~66, VOK should be ~19, HR should be ~139
collectExeData(1) # W should be ~132, VOK should be ~35, HR should be ~196

# Call function 2
writeData(collectExeData(0),"MinWR")
writeData(collectExeData(0.8),"E80")
writeData(collectExeData(1),"MaxWR")
}