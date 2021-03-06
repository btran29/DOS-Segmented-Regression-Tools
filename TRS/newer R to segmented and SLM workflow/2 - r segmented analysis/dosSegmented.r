# Function to run segmented over data
# Given an input of a linear-modeled variable, number of breakpoints to
# specify, and either 0, 1, or 2 guessed breakpoint locations:
# 	Run segmented over data
# Output: segmented output in a list
# REQUIRED PACKAGE: segmented
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


# Function to convert data into a linear model
linearize <- function(yaxis,xaxis){
	varData		<- data.frame(x=xaxis,y=yaxis)
	linearMod	<- lm(y~x,data=varData)
	return(linearMod)
}

# Test code #
test <- FALSE
if(test){
# Generate pre-requisites
csv <- dir(pattern="*csv")

# Obtain breakpoints
setwd("batch files")
table <- read.csv("study phase markers batch file.csv")
setwd("..")

# Assign Data
csvData		<- read.csv(csv[1],header = TRUE)
normTime	<- csvData[[1]]-min(csvData[[1]])
BO  <- data.frame(x=normTime, y=csvData[[2]])
BR  <- data.frame(x=normTime, y=csvData[[3]])
BT  <- data.frame(x=normTime, y=csvData[[4]])
BS  <- data.frame(x=normTime, y=csvData[[5]])

# Convert data into linear models
lin	<- list(
  "HbO2"  = lm.BO  <- lm(y~x,data=BO),
  "HbR"  = lm.BR  <- lm(y~x,data=BR),
  "THb"  = lm.BT  <- lm(y~x,data=BT),
  "stO2"  = lm.BS  <- lm(y~x,data=BS)
)

# Specify bootstrap iterations to find breakpoints
seg.it <- 10

# Specify breakpoints
segmentedMethod	<- table$SpecifSegmentedBPs
segmentedBP1	<- table$FirstGuess
segmentedBP2	<- table$SecondGuess

# Call function
if (exists("bpOutput")==FALSE){
	bpOutput <- sapply(lin,DOSI.segmented,2,3,7,simplify=FALSE,USE.NAMES=TRUE)}

# HbO2 (oBO) should have breakpoints around 0.5 min and 7.6 min
# HbR (oBR) should have breakpoints around 0.5 min and 5.7 min
# See sample figure for a visualization
}
