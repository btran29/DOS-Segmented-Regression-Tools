# Function to locate equivalent exercise
# 	Given an input of study name:
#		Split it by spaces, then compare with other studies in the file-list
#		until EXE study with same EXO, date, & visit is found
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


# Function to run segmented over data
# Given an input of a linear-modeled variable, number of breakpoints to
# specify, and either 0, 1, or 2 guessed breakpoint locations:
# 	Run segmented over data
# Output: segmented output in a list
DOSI.segmented <- function(var,specifiedBPs,segmentedBP1,segmentedBP2){
  try({
      if (specifiedBPs == 0){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=NA),
                          control=seg.control(stop.if.error=FALSE,n.boot=0,
						  it.max=seg.it))
    } else if (specifiedBPs == 1){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=segmentedBP1),
                          control=seg.control(display=FALSE,n.boot=50,
						  it.max=seg.it))
    } else if (specifiedBPs == 2){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=c(segmentedBP1,segmentedBP2)),
                          control=seg.control(display=FALSE,n.boot=50,
						  it.max=seg.it))
    } # end specified bp conditionals
    }) # end try statement

  # If the method fails, fill breakpoint data with a dummy value
  if(exists("varOut")==FALSE){
    varOut <- vector(mode="list", length=0)
    varOut$psi <- matrix(0, nrow = 2, ncol = 3)
  }
  return(varOut)
}


# Function to find data at exercise levels of interest
# Given an input of percentage e.g. (.5 for 50%) of work-rate:
#	locate the equivalent exercise data at that percentage
#	average +/- span for key variables
# Output: average W, VOK, HR, VE + standard deviations
collectExeData <- function(argv){

	# Percentage of max work rate
	percentWorkRate = argv*max(W)
	percentExeTime  = argv*max(exeTime)
	
	# Factor over which to average data
	span = (5/60)

	
	if(argv == max(W)){
	# Case for max W
		equivExeTime       <- tail(W, n=1)[[1]][1]
		indLequivExeTime   <- which(abs((equivExeTime-2*span)-exeTime)==min(abs((equivExeTime-span)-exeTime)))
		indUequivExeTime   <- which(equivExeTime==exeTime)
	} else if(argv == 0){
	# Case for min W
		equivExeTime       <- head(W, n=1)[[1]][1]
		indLequivExeTime   <- which(equivExeTime==exeTime)
		indUequivExeTime   <- which(abs((equivExeTime+2*span)-exeTime)==min(abs((equivExeTime+span)-exeTime)))
	} else {
	# Case for all other percentages of W
		equivExeTime	<- exeTime[which(abs(percentExeTime-exeTime)==min(abs(percentExeTime-exeTime)))]
		indLequivExeTime   <- which(abs((equivExeTime-span)-exeTime)==min(abs((equivExeTime-span)-exeTime)))
		indUequivExeTime   <- which(abs((equivExeTime+span)-exeTime)==min(abs((equivExeTime+span)-exeTime)))

	}

	# Initialize vectors to collect data 
	bpAvgW			<- vector()
	bpAvgWstDev		<- vector()
	bpAvgVOK		<- vector()
	bpAvgVOKstDev	<- vector()
	bpAvgHR			<- vector()
	bpAvgHRstDev	<- vector()
	bpAvgVE			<- vector()
	bpAvgVEstDev	<- vector()
	
	
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
						  bpAvgW,bpAvgWstDev,
						  bpAvgVOK,bpAvgVOKstDev,
						  bpAvgHR,bpAvgHRstDev,
						  bpAvgVE,bpAvgVEstDev,
						  bpRelTime)
	return(perWRdata)
}


# Function to write data
# Given an input of a collectExeData data frame, and a label e.g "Maximum 
# work-rate data":
#	Append contents of the data frame onto the output file name
# Output: no direct output, data in csv
writeData <- function(argv, label){
  for(iArgV in 1:length(argV)){
  	write.table(paste((names(argV)[iArgV]),label,sep=" "),
		paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,
		row.names=FALSE)

    write.table(argV[iArgV],
		paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,
		row.names=FALSE)
  }
}


# Function to generate standardized figures
# Given an input of 'segmented' data for a variable (e.g. HbR), time label
# e.g. "Time (min)", y-axis label e.g. "[HbR] (uM)", and figure title e.g.
# "PFC HbR":
#	draw figure with breakpoints denoted as vertical lines
# Output: no direct output
bpFigures <- function(variable,xAxisLabel,yAxisLabel,title){
  # Variable data over a 12 minute time axis
  plot(variable$model$x,variable$model$y, xlim=c(min(normTime),(min(normTime)+13)), ann=FALSE)
  # Labels after base data points
  mtext(side = 1, text = xAxisLabel, line = 2)
  mtext(side = 2, text = yAxisLabel, line = 2)
  mtext(side = 3, text = title, line = 0, font = 2)
  # Segmented data
  lines(variable$model$x,variable$fitted.values)
  lines(variable,lwd = 2, col= 553, lty =1,shift = TRUE, pch = 0,cex=10, k =1.8)
  # Vertical Lines
  for(iLine in 1:(length(variable$psi)/3)){
    abline(v =variable$psi[iLine,2] , untf = FALSE, lty=2)
  }
}
