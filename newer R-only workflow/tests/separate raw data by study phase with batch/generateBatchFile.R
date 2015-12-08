## Clean up

#############################################################################
## Generate batch file from current csv format data files
# Example: "generateBatch(_RAMP)"
# looks for all csv files ending in _RAMP
generateBatch <- function(arg1){
  # Locate all applicable files for threshold analysis
  csv <- dir(pattern=paste("*",arg1,".csv",sep=""))

  # Temporary data-table
  default <- vector(mode = "numeric",length = (length(csv)))
  table   <- data.frame(File=csv, SpecifSegmentedBPs=default,
                        FirstGuess=default, SecondGuess=default)

  # Write
  #write.table(table,"dosi batch.csv",append=FALSE,row.names=FALSE,sep=",")
  write.table(table,"study phase markers batch file.txt",append=FALSE,row.names=FALSE,sep="\t")

}

generateBatch("")


#############################################################################
## Separate by markers
#############################################################################
## Select ramp data and run segmented based on batch file
# Import segmented data (by trial and error)
segmentedBPinput <- read.table("segmented batch.txt", header=TRUE,sep="\t")

# Iterations per segmented call
seg.it <- 10

# Make overlay plots? REQUIRES ALL STUDIES TO BE RUN
overlayPlots <- TRUE

# Get working directory for output
workingDir <- getwd()

# List files of interest in working directory
csv <- dir(pattern="*.csv")

# Separate keywords in filenames by space
splitCSV <- strsplit(csv," ") # list

# Locate optical data by keyword
csvData   <- csv[grepl("PFC",splitCSV)]
indCsvData <- grep("PFC",splitCSV)

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


# Progress bar
pb = winProgressBar(title="DOSI Processing Progress",min = 0, max = 100, initial = 0, width = 300,label="0%")

# Loop over data files
i <- 1

# Print current study into console (for progress & error tracking)
cat("======\n")
cat(paste(substr(csvData[i],1,13), "\n"))
cat(paste(substr(csvExe[indExe],1,11), "\n"))

# Set progress (for progress & error tracking)
setWinProgressBar(pb,(i/length(csv)*100),label=sprintf("%g%%",(i/length(csv)*100)))

# Get base file name for outputs
outputFileName <- paste(workingDir,"/rawOut_",paste(substr(csvData[i],1,13)),"_", sep="")

# Assign data in file to a data frame after normalizing time
csvData    <- read.csv(csvData[i], header = TRUE)
csvExeData <- read.csv(csvExe[indExe], header = TRUE)

Time     <- csvData[[1]]
normTime <- Time-min(Time)
exeTime  <- csvExeData[[1]]

BO  <- data.frame(x=normTime, y=csvData[[2]])
BR  <- data.frame(x=normTime, y=csvData[[3]])
BT  <- data.frame(x=normTime, y=csvData[[4]])
BS  <- data.frame(x=normTime, y=csvData[[5]])
VEO <- data.frame(x=exeTime, y=csvExeData[[2]])
VEC <- data.frame(x=exeTime, y=csvExeData[[3]])
PO  <- data.frame(x=exeTime, y=csvExeData[[4]])
PC  <- data.frame(x=exeTime, y=csvExeData[[5]])
VO  <- data.frame(x=exeTime, y=csvExeData[[6]])
VOK <- data.frame(x=exeTime, y=csvExeData[[7]])
VC  <- data.frame(x=exeTime, y=csvExeData[[8]])
VE  <- data.frame(x=exeTime, y=csvExeData[[9]])
HR  <- data.frame(x=exeTime, y=csvExeData[[10]])
RR  <- data.frame(x=exeTime, y=csvExeData[[11]])
RPM <- data.frame(x=exeTime, y=csvExeData[[12]])
W   <- data.frame(x=exeTime, y=csvExeData[[13]])

out <-list(
  "oBO"  = lm.BO  <- lm(y~x,data=BO),
  "oBR"  = lm.BR  <- lm(y~x,data=BR),
  "oBT"  = lm.BT  <- lm(y~x,data=BT),
  "oBS"  = lm.BS  <- lm(y~x,data=BS),
  "oVEO" = lm.VEO <- lm(y~x,data=VEO),
  "oVEC" = lm.VC  <- lm(y~x,data=VEC),
  "oPO"  = lm.PO  <- lm(y~x,data=PO),
  "oPC"  = lm.PC  <- lm(y~x,data=PC),
  "oVO"  = lm.VO  <- lm(y~x,data=VO),
  "oVC"  = lm.VC  <- lm(y~x,data=VC),
  "oVE"  = lm.VE  <- lm(y~x,data=VE),
  "oHR"  = lm.HR  <- lm(y~x,data=HR),
  "oRR"  = lm.RR  <- lm(y~x,data=RR),
  "oRPM" = lm.RPM <- lm(y~x,data=RPM)
)

# Number of breakpoints specified for 'segmented' package
segmentedMethod <- segmentedBPinput$SpecifSegmentedBPs[i]
segmentedBP1    <- segmentedBPinput$FirstGuess[i]
segmentedBP2    <- segmentedBPinput$SecondGuess[i]

# Function to run segmented over data
DOSI.segmented <- function(var,specifiedBPs,segmentedBP1,segmentedBP2){
  try({
      if (specifiedBPs == 0){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=NA),
                          control=seg.control(stop.if.error=FALSE,n.boot=0, it.max=seg.it))
    } else if (specifiedBPs == 1){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=segmentedBP1),
                          control=seg.control(display=FALSE,n.boot=50, it.max=seg.it))
    } else if (specifiedBPs == 2){
      varOut <- segmented(var,seg.Z=~x,psi=list(x=c(segmentedBP1,segmentedBP2)),
                          control=seg.control(display=FALSE,n.boot=50, it.max=seg.it))
    } # end specified bp conditionals
    }) # end try statement

  # If the method fails, fill breakpoint data with a dummy value
  if(exists("varOut")==FALSE){
    varOut <- vector(mode="list", length=0)
    varOut$psi <- matrix(0, nrow = 2, ncol = 3)
  }
  return(varOut)
}

# Function to collect individual breakpoint data
collectBPdata <- function(arg1){
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

  # Try statement ensures that there is a array for sapply, even if there is no applicable data
  try({
    if(length(arg1$psi[,2])>=1){
      for (iConfint in 1:length(arg1$psi[,2])){
        # Collect confint data
        bpEstX[iConfint]   <- confint(arg1)[[1]][[iConfint]]
        bpEstY[iConfint]   <- arg1$fitted.values[which(abs(arg1$psi[iConfint,2]-arg1$model$x)==
                                                         min(abs(arg1$psi[iConfint,2]-arg1$model$x)))]
        lConf[iConfint]    <- confint(arg1)[[1]][length(arg1$psi[,2])*1+iConfint]
        uConf[iConfint]    <- confint(arg1)[[1]][length(arg1$psi[,2])*2+iConfint]
        confDiff[iConfint] <- abs(lConf[iConfint]-bpEstX[iConfint])

        # Find equivalent exercise data by averaging exe data +/- 5 seconds noted by breakpoint
        # Get equivalent time indicies +/- 5 seconds noted by breakpoint
        equivExeTime       <- exeTime[which(abs(bpEstX[iConfint]-exeTime)==min(abs(bpEstX[iConfint]-exeTime)))]
        indLequivExeTime   <- which(abs((equivExeTime-(5/60))-exeTime)==min(abs((equivExeTime-(5/60))-exeTime)))
        indUequivExeTime   <- which(abs((equivExeTime+(5/60))-exeTime)==min(abs((equivExeTime+(5/60))-exeTime)))

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

# Collect individual breakpoint data over all variables
bpOutput2<-sapply(bpOutput,collectBPdata,simplify=FALSE,USE.NAMES=TRUE)

# Write segmented data into a text file
for(ibpOutput in 1:length(bpOutput2)){
  write.table(paste(names(bpOutput)[ibpOutput],substr(csvData[i],1,13)),
              paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,row.names=FALSE)
  write.table(bpOutput2[ibpOutput],
              paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE, row.names=FALSE)
}

# Collect data at maximum work-rate

# Initialize vectors
maxWR <- max(W)

# Find equivalent exercise indicies
equivExeTime       <- tail(W, n=1)[[1]][1]
indLequivExeTime   <- which(abs((equivExeTime-(10/60))-exeTime)==min(abs((equivExeTime-(10/60))-exeTime)))
indUequivExeTime   <- which(equivExeTime==exeTime)

# Average data over final 10s of exercise
AvgVOK      <- mean(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])
AvgVOKstDev <- sd(VOK$y[indLequivExeTime[1]:indUequivExeTime[1]])

AvgHR       <- mean(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])
AvgHRstDev  <- sd(HR$y[indLequivExeTime[1]:indUequivExeTime[1]])

AvgVE       <- mean(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])
AvgVEstDev  <- sd(VE$y[indLequivExeTime[1]:indUequivExeTime[1]])

# Collect all exercise averaged data into a data frame
maxWRData <- data.frame(AvgVOK,AvgVOKstDev,
                        AvgHR,AvgHRstDev,
                        AvgVE,AvgVEstDev)

# Write maximum work-rate data into table
write.table(paste(substr(csvData[i],1,4),"Maximum work-rate data",sep=" "),
            paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE,row.names=FALSE)

for(iMaxWRData in 1:length(maxWRData)){
  write.table(maxWRData[iMaxWRData],
              paste(outputFileName,"Data.csv",sep=""), sep=",", append=TRUE, row.names=FALSE)
}

# Collect study data in global environment
studyData  <- list(bpOutput,bpOutput2,maxWRData)
if(exists("ExeDOSI")==FALSE){
  ExeDOSI    <- vector(mode="list", length=length(csv))
}
if(exists("ExeDOSI")==TRUE){
  ExeDOSI[i] <- list(studyData)
} # to reference segmented, ExeDOSI[[i]][[1]]; to reference confint, ExeDOSI[[i]][[2]]

# Figures function
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

# Figures; Used try statements as some data is known to be too noisy to all have breakpoints or successful
# segmented calls

# Fig 1
cat(paste("BRBS","\n"))
pdf(paste(outputFileName,"BRBS.pdf",sep=""))
try({bpFigures(bpOutput$oBR,"Time (min)","[HbR] (uM)","PFC HbR")})
try({bpFigures(bpOutput$oBS,"Time (min)","stO2 (uM)","PFC stO2")})
dev.off()

# Fig 2
cat(paste("BOBT","\n"))
pdf(paste(outputFileName,"BOBT.pdf",sep=""))
try({bpFigures(bpOutput$oBO,"Time (min)","HbO2 (uM)","PFC HbO2")})
try({bpFigures(bpOutput$oBT,"Time (min)","THb (uM)","PFC THb")})
dev.off()


# Fig 3
cat(paste("VEPC2","\n"))
pdf(paste(outputFileName,"VEPC2.pdf",sep=""))
try({bpFigures(bpOutput$oVE,"Time (min)","VE (L/min)","VE")})
try({bpFigures(bpOutput$oPC,"Time (min)","PETCO2 mmHg","PETCO2")})
dev.off()

# Fig 4
cat(paste("HRBOf","\n"))
pdf(paste(outputFileName,"HRBOf.pdf",sep=""))
try({bpFigures(bpOutput$oHR,"Time (min)","HR","HR")})
try({bpFigures(bpOutput$oBOf,"Time (min)","BO FAC","BO FAC")})
dev.off()

# Remove Variables to prevent overwriting data
rm(out,bpOutput,bpOutput2,fivebreakpoints)

# End of length(csv) loop for initial segmented calls + plotting
# end loop over data files


#############################################################################
## Output collected segmented data into separate variable workbooks
