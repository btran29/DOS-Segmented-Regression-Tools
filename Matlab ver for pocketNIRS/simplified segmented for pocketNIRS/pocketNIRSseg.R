## Set up initial files ##
# List studies of interest
directory	<- dir(pattern="*.csv")

# Set data file of interest
dosData.fid <- directory[2]

# Grab data from pre-formatted CSV file
# Each testing session is one column, time is on axis
# Time axis is normalized to start of testing session and shared across sessions
dosdata <- read.csv(dosData.fid)
dosdata.numberofstudies <-length(colnames(dosdata)[-1])

# Segmented input table for each session
# WARNING WILL OVERWRITE CURRENT TABLE
# Four column long-style table
default <- vector(mode = "numeric",length = length(dosdata.numberofstudies))
seg.input.fid <- paste("segmentedInput",dosData.fid,sep="_")
table   <- data.frame(file=colnames(dosdata)[-1],
                      specifiedBPs=default,
                      segBP1=default,
                      segBP2=default)
write.table(table,seg.input.fid,append=FALSE,row.names=FALSE,sep=",")

# Set segmented input file of interest
directory	<- dir(pattern="*.csv")
seg.input.fid <- directory[4]



## Analysis ##
# Read input
seg.it <- 10
seg.input <- read.csv(seg.input.fid)

# Initialize breakpoint collection variable
bp.output <- replicate(dosdata.numberofstudies, list()) 
#bp.output <- vector(mode = "list", length = dosdata.numberofstudies)

# Collect intial guessing data for segmented
# Workflow note: play with values until segmented works for a session
# If no values work/data is undecipherable, leave at 0 specified BPs
# Expand loop to eventually cover entire number of available studies
for (session in 1:dosdata.numberofstudies){

  var.column <- session+1
  var <- data.frame(x=dosdata$Time, y=dosdata[,var.column])
  var.lm  <- lm(y~x,data=var)

  # Run segmented into collection variable
  try({
    if (seg.input$specifiedBPs[session] == 0){
      seg.out <- segmented(var.lm,seg.Z=~x,psi=list(x=NA),
                          control=seg.control(stop.if.error=FALSE,n.boot=0,
                                              it.max=seg.it))
    } else if (seg.input$specifiedBPs[session] == 1){
      seg.out <- segmented(var.lm,seg.Z=~x,psi=list(x=c(seg.input$segBP1[session])),
                           control=seg.control(display=FALSE,n.boot=50,
                                               it.max=seg.it))
    } else if (seg.input$specifiedBPs[session] == 2){
      seg.out <- segmented(var.lm,seg.z=~x,psi=list(x=c(seg.input$segBP1[session],seg.input$segBP2[session])),
                           control=seg.control(display=FALSE,n.boot=50,
                                               it.max=seg.it))
    } # end specified bp conditionals
  }) # end try statement
  
  bp.output[[session]] <- seg.out #Save seg.out (list datatype) into bp.output list
  rm(seg.out,var.lm)
}

# Collect BP Data, using collectBPdata function
normTime <- dosdata$Time # required by collectBPdata
bp.outputlist <-sapply(bp.output,collectBPdata,span,hasExeData=FALSE,simplify=FALSE,USE.NAMES=TRUE)

# Remove data for sessions with >2 bp, or were supposed to have 0 bp
for (session in 1:dosdata.numberofstudies){
  if (seg.input$specifiedBPs[session] ==0 || length(bp.outputlist[[session]]$bpEstX)>2){
    bp.outputlist[[session]] <- data.frame(bpEstX=double(),
                                           bpEstY=double(),
                                           lConf=double(),
                                           uConf=double(),
                                           bpRelTime=double())
  }
}

# Make list of file names
session.fid <- vector(mode="character", length = dosdata.numberofstudies) #Initialize empty vector
for (session in 1:dosdata.numberofstudies){
  seg.out.fid <-  paste("segmentedOutput",dosData.fid,sep="_")
  session.fid[[session]] <- colnames(dosdata)[session+1] # Skip time in column names
}

# Concatenate file names 
for (session in 1:dosdata.numberofstudies){
  if (length(bp.outputlist[[session]]$bpEstX)==1){
  bp.outputlist[[session]]$file <- session.fid[[session]]
  bp.outputlist[[session]] <-  bp.outputlist[[session]][c(7,1,2,3,4,5,6)] # file names to 1st column
  }
}

# Write to table
for (session in 1:dosdata.numberofstudies){
  seg.out.fid <-  paste("segmentedOutput",dosData.fid,sep="_")
  if(session==1){ # Create column names with first set of data
    write.table(bp.outputlist[[session]],file=seg.out.fid,append=T, sep=",",row.names = F)  
  } else if(session>1){ # Just write row w/out column names
    write.table(bp.outputlist[[session]],file=seg.out.fid,append=T, sep=",",row.names = F,col.names=F)
  }
}