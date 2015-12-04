# Function to collect individual breakpoint data
# Given a 'segmented' output for a particular variable:
#	for every breakpoint:
#		collect its X/Y-axis info, confidence intervals
#		collect exercise data at equivlanet timepoint averaged
#			+/- span (e.g. +/- 5 seconds)
#		compile this data into a data frame
# Output: data frame
collectBPdata <- function(argv){
  # Pre-allocate temporary vectors
  # Segmented variables of interest
  bpEstX      <- vector()
  bpEstY      <- vector()
  bpWork      <- vector()
  bpRelTime   <- vector()
  lConf       <- vector()
  uConf       <- vector()
  confDiff    <- vector()

  # Exercise variables of interest
  bpAvgW        <- vector()
  bpAvgWstDev   <- vector()
  bpAvgVOK      <- vector()
  bpAvgVOKstDev <- vector()
  bpAvgHR       <- vector()
  bpAvgHRstDev  <- vector()
  bpAvgVE       <- vector()
  bpAvgVEstDev  <- vector()

  # Span over which to average exercise data
  span	<- (5/60)

  # Try statement ensures that there is an array for sapply, even if
  # there is no applicable data
  try({
    if(length(argv$psi[,2])>=1){
      for (iConfint in 1:length(argv$psi[,2])){
        # Collect confint data
        bpEstX[iConfint]   <- confint(argv)[[1]][[iConfint]]
        bpEstY[iConfint]   <- argv$fitted.values[which(abs(argv$psi[iConfint,2]-argv$model$x)==
								min(abs(argv$psi[iConfint,2]-argv$model$x)))]
        lConf[iConfint]    <- confint(argv)[[1]][length(argv$psi[,2])*1+iConfint]
        uConf[iConfint]    <- confint(argv)[[1]][length(argv$psi[,2])*2+iConfint]
        confDiff[iConfint] <- abs(lConf[iConfint]-bpEstX[iConfint])

        # Find equivalent exercise data by averaging exe data +/- 5 seconds noted by breakpoint
        # Get equivalent time indicies +/- 5 seconds noted by breakpoint
        equivExeTime       <- exeTime[which(abs(bpEstX[iConfint]-exeTime)==min(abs(bpEstX[iConfint]-exeTime)))]
        indLequivExeTime   <- which(abs((equivExeTime-span)-exeTime)==min(abs((equivExeTime-span)-exeTime)))
        indUequivExeTime   <- which(abs((equivExeTime+span)-exeTime)==min(abs((equivExeTime+span)-exeTime)))

        # Average exe data over +/- 5 seconds from breakpoint
        bpAvgW[iConfint]      <- mean(W$y[indLequivExeTime[1]:indUequivExeTime[1]])
        bpAvgWstDev[iConfint] <- sd(W$y[indLequivExeTime[1]:indUequivExeTime[1]])

        bpAvgVOK[iConfint]      <- mean(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])
        bpAvgVOKstDev[iConfint] <- sd(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])

        bpAvgHR[iConfint]      <- mean(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])
        bpAvgHRstDev[iConfint] <- sd(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])

        bpAvgVE[iConfint]      <- mean(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])
        bpAvgVEstDev[iConfint] <- sd(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])

        # Find breakpoint time/total ramp time
        bpRelTime[iConfint] <- bpEstX[iConfint]/max(normTime)
      }
    }
  })
  confintData <- data.frame(# Segmented variables of interest
    bpEstX,bpEstY,lConf,uConf,confDiff,
    # Exercises Variables of interest
    bpAvgW,bpAvgWstDev,
    bpAvgVOK,bpAvgVOKstDev,
    bpAvgHR,bpAvgHRstDev,
    bpAvgVE,bpAvgVEstDev,
    bpRelTime)
  return(confintData)
}

# Test code #

# REQUIRES 'segmented' to be loaded in order to interpret loaded sample
# breakpoint data

# Create pre-requisite sample data
csv <- dir(pattern="*csv")

# Assign Data
csvExeData		<- read.csv(csv[1],header = TRUE)
normTime	<- csvExeData[[1]]-min(csvExeData[[1]])
exeTime	<- csvExeData[[1]]
VOK		<- data.frame(x=exeTime, y=csvExeData[[7]])
VE		<- data.frame(x=exeTime, y=csvExeData[[9]])
HR		<- data.frame(x=exeTime, y=csvExeData[[10]])
W		<- data.frame(x=exeTime, y=csvExeData[[13]])

outputFileName <- "EXO-1 AaAa V3 11-11-11 "


load("bpOutput")

# Call function over all variables
bpOutput2<-sapply(bpOutput,collectBPdata,simplify=FALSE,USE.NAMES=TRUE)


# Write segmented data into a text file
for(ibpOutput in 1:length(bpOutput2)){
  write.table(paste(names(bpOutput)[ibpOutput]),
              paste(outputFileName,"Data.txt",sep=""), sep="\t", append=TRUE,
			  row.names=FALSE)
  write.table(bpOutput2[ibpOutput],
              paste(outputFileName,"Data.txt",sep=""), sep="\t", append=TRUE,
			  row.names=FALSE)
}
