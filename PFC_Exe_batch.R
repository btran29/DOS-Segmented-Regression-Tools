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
# Updated 8/21/15 Brian

# Get working directory for output
workingDir <- getwd()

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


# Batch loop
for(i in 1:length(csv))
{
  # Obtain data from current file
  csvData <- read.csv(csv[i], header = TRUE)
  Time    <- csvData[[1]]
  L.HbR   <- data.frame(x=Time, y=csvData[[3]])

  # Convert data to linear model for segmented
  L.HbR.lm <- lm(y~x,data=L.HbR)

  # Run segmented as output
  out.L.HbR <- DOSI.segmented(L.HbR.lm,twopoints=FALSE)

  # Get base file name for outputs
  outputFileName <- paste(workingDir,"/",paste(substr(csv[i],1,13)),"_", sep="")

  # Generate figures
  cat(paste("BRBS","\n"))
  #pdf(paste(outputFileName,"LHbR.pdf",sep="."))
  png(filename = paste(outputFileName,"LHbR.png",sep="."),
      width = 1024, height = 1024, units = "px", pointsize = 16)

  try({bpFigures(out.L.HbR,"Time (sec)","[HbR] (uM)","PFC HbR")})
  dev.off()

}
