# Exercise Threshold Locating Script for DOSI
#
# This script takes all csv files in the working directory, runs
# the segmented package (with experimental threshold-guessing)
# on the HbR data, then generates a figure in the working
# directory.
#
# Can be run on binned/unbinned data!
#
# Required packages: segmented
# Updated 10/27/15 Brian

useOnePointMethod <- FALSE

# Get working directory for output
workingDir <- getwd()

# Create subdirectory for output
# subdir <- paste(workingDir,'/R Threshold Output',sep = "")
# subDir <- 'R Threshold Output'
# ifelse(!dir.exists(file.path(workingDir, subDir)), dir.create(file.path(workingDir, subDir)), FALSE)

# Locate files of interest
csv <- dir(pattern="*.csv")

# Segmented iterations to run
seg.it <- 100

# Function to run segmented over data
DOSI.segmented <- function(var,twopoints=TRUE,arg2,arg3){
  try({
    if(!twopoints){varOut <- segmented(var,seg.Z=~x,psi=list(x=NA),control=seg.control(stop.if.error=FALSE,n.boot=0, it.max=seg.it))
    } else{varOut <- segmented(var,seg.Z=~x,psi=list(x=c(arg2,arg3)),control=seg.control(display=FALSE,n.boot=50, it.max=seg.it))}
  })
  # If the method fails, fill breakpoint data with a dummy value
  if(exists("varOut")==FALSE){
    varOut <- vector(mode="list", length=0)
    varOut$psi <- matrix(0, nrow = 2, ncol = 3)
  }
  return(varOut)
}

# Function to generate figures
bpFigures <- function(variable,xAxisLabel,yAxisLabel,title){
  # Variable data over a 12 minute time axis
  plot(variable$model$x,variable$model$y,ann=FALSE)
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

# Function to collect individual breakpoint data
collectBPdata <- function(arg1){
  # Pre-allocate temporary vectors
  # Segmented variables of interest
  bpEstX      <- vector()
  bpEstY      <- vector()
  bpRelTime   <- vector()
  lConf       <- vector()
  uConf       <- vector()
  confDiff    <- vector()

  if(length(arg1$psi[,2])>=1){
    for (iConfint in 1:length(arg1$psi[,2])){
      # Collect confint data
      bpEstX[iConfint]   <- confint(arg1)[[1]][[iConfint]]
      bpEstY[iConfint]   <- arg1$fitted.values[which(abs(arg1$psi[iConfint,2]-arg1$model$x)==
                                                       min(abs(arg1$psi[iConfint,2]-arg1$model$x)))]
      lConf[iConfint]    <- confint(arg1)[[1]][length(arg1$psi[,2])*1+iConfint]
      uConf[iConfint]    <- confint(arg1)[[1]][length(arg1$psi[,2])*2+iConfint]
      confDiff[iConfint] <- abs(lConf[iConfint]-bpEstX[iConfint])

      # Find breakpoint time/total ramp time
      bpRelTime[iConfint] <- bpEstX[iConfint]/max(normTime)
    }
  }

  confintData <- data.frame(
    # Segmented variables of interest
    bpEstX,
    bpEstY,
    lConf,
    uConf,
    confDiff,
    bpRelTime)
  return(confintData)
}

# Batch loop with main method
message("Starting analysis (progress shown with Subject ID) \n")

for(i in 1:length(csv)){

  # Show current study in console
  cat(paste(" ",substr(csv[i],1,4),"\n"))

  # Obtain data from current file
  csvData <- read.csv(csv[i], header = TRUE)

  # Normalize time data
  Time    <- csvData[[1]]
  normTime <- Time-min(Time)

  # Variables used
  HbR   <- data.frame(x=normTime, y=csvData[[3]])

  # Convert data to linear model for segmented
  out <-list(
    "HbR.lm"  = HbR.lm <- lm(y~x,data=L.HbR)
  )

  # Run segmented as output

  # Auto-find points method
  if(!useOnePointMethod){
    bpOutput <- sapply(out,DOSI.segmented,twopoints=FALSE,simplify=FALSE,USE.NAMES=TRUE)
  }

  # Two-points method, reverting to auto-find if boundary error occurs
  if(useOnePointMethod){
    # Find time indicies corresponding to 1/3 and 2/3 of the total time
    firstPoint  <- abs(normTime-(2/3)*(max(normTime)))
    secondPoint <- abs(normTime-(2/3)*(max(normTime)))

    ind.firstPoint  <- which(firstPoint  == min(firstPoint))
    ind.secondPoint <- which(secondPoint == min(secondPoint))


    bpOutput <- tryCatch({
      sapply(out,DOSI.segmented,twopoints=TRUE,normTime[ind.firstPoint],normTime[ind.secondPoint],simplify=FALSE,USE.NAMES=TRUE)
    },error = function(e) e)

    if(!inherits(bpOutput, "error")){
      bpOutput <- sapply(out,DOSI.segmented,twopoints=FALSE,simplify=FALSE,USE.NAMES=TRUE)
    }

  } # end two-points conditional

  # Get base file name for outputs
  outputFileName <- paste(workingDir,"/",paste(substr(csv[i],1,13)),"_", sep="")


  # Collect individual breakpoint data over all variables
  bpOutput2<-sapply(bpOutput,collectBPdata,simplify=FALSE,USE.NAMES=TRUE)

  # Write segmented data into a text file
  for(ibpOutput in 1:length(bpOutput2)){
    write.table(paste(names(bpOutput)[ibpOutput],csv[i]),
                paste(outputFileName,"Data.csv",sep=""), sep=",",
                append=TRUE,row.names=FALSE)
    write.table(bpOutput2[ibpOutput],
                paste(outputFileName,"Data.csv",sep=""), sep=",",
                append=TRUE, row.names=FALSE)
  } # end csv output loop

  # Generate figures

  # Plot only if data for particular variable is present
  if(length(bpOutput$HbR.lm$psi[,2])>=1){
    png(filename = paste(outputFileName,"HbR.png",sep="."),
        width = 1024, height = 1024, units = "px", pointsize = 16)
    bpFigures(bpOutput$L.HbR.lm,"Time (sec)","[HbR] (uM)","PFC HbR")
    dev.off()
  } # end conditional for L.HbR figure

} # end .csv file loop
