## Set up initial files ##
# List studies of interest
directory	<- dir(pattern="*.csv")

# Set data file of interest
dosData.fid <- directory[1]

# Grab data from pre-formatted CSV file
# Each testing session is one column, time is on axis
# Time axis is normalized to start of testing session and shared across sessions
dosdata <- read.csv(dosData.fid)
dosdata.numberofstudies <-length(colnames(dosdata)[-1])

########################################
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
#######################################


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

# Initalize time collection variable
time.output <- vector(mode="list", length=dosdata.numberofstudies)

# Collect intial guessing data for segmented
# Workflow note: play with values until segmented works for a session
# If no values work/data is undecipherable, leave at 0 specified BPs
# Expand loop to eventually cover entire number of available studies
library(segmented)
for (session in 1:dosdata.numberofstudies){
  
  var.column <- session+1
  var <- data.frame(x=dosdata$Time, y=dosdata[,var.column])
  var.lm  <- lm(y~x,data=var)
  
  # Run segmented into collection variable
  try({
    if (seg.input$specifiedBPs[session] == 0){
      seg.out <- segmented(var.lm,seg.Z=~x,psi=list(x=10),
                           control=seg.control(stop.if.error=FALSE,n.boot=0,
                                               it.max=seg.it))
    } else if (seg.input$specifiedBPs[session] == 1){
      seg.out <- segmented(var.lm,seg.Z=~x,psi=list(x=c(seg.input$segBP1[session])),
                           control=seg.control(display=FALSE,n.boot=50,
                                               it.max=seg.it))
    } else if (seg.input$specifiedBPs[session] == 2){
      seg.out <- segmented(var.lm,seg.Z=~x,psi=list(x=c(seg.input$segBP1[session],seg.input$segBP2[session])),
                           control=seg.control(display=FALSE,n.boot=50,
                                               it.max=seg.it))
    } # end specified bp conditionals
  }) # end try statement
  
  bp.output[[session]] <- seg.out #Save seg.out (list datatype) into bp.output list
  rm(seg.out,var.lm)
  
  # Generate time axis for every study
  time.output[[session]] <- length(var$y[!is.na(var$y)])*10 # 10 second bins
}



# Collect BP Data, using collectBPdata function
span = 0
bp.outputlist <- mapply(collectBPdata,bp.output,time.output,span,hasExeData=FALSE,USE.NAMES =TRUE,SIMPLIFY = FALSE)

# Remove data for sessions with >2 bp, or were considered uninterpretable
for (session in 1:dosdata.numberofstudies){
  if (seg.input$specifiedBPs[session] ==0 || length(bp.outputlist[[session]]$bpEstX)>2){
    bp.outputlist[[session]] <- data.frame(bpEstX=double(),
                                           bpEstY=double(),
                                           lConf=double(),
                                           uConf=double(),
                                           bpRelTime=double())
  }
}


## Cleaned output with only latest breakpoint
# Make a copy for the cleaned output
bp.outputlist.cleaned <- bp.outputlist
# For the cleaned output, select only second data point if there are testing sessions with 2 break points
for (session in 1:dosdata.numberofstudies){
  if (length(bp.outputlist.cleaned[[session]]$bpEstX) == 2){
    bp.outputlist.cleaned[[session]] <- bp.outputlist.cleaned[[session]][2,]
  }
}

# Make list of file names
session.fid <- vector(mode="character", length = dosdata.numberofstudies) #Initialize empty vector
for (session in 1:dosdata.numberofstudies){
  seg.out.fid <-  paste("segmentedOutput",dosData.fid,sep="_")
  session.fid[[session]] <- colnames(dosdata)[session+1] # Skip time in column names
}

# Concatenate file names of studies that have data
for (session in 1:dosdata.numberofstudies){
  if (length(bp.outputlist.cleaned[[session]]$bpEstX)==1){
    bp.outputlist.cleaned[[session]]$file <- session.fid[[session]]
    bp.outputlist.cleaned[[session]] <-  bp.outputlist.cleaned[[session]][c(7,1,2,3,4,5,6)] # file names to 1st column
  }
}
# Concatonate timeEnd of studies that have data
for (session in 1:dosdata.numberofstudies){
  if (length(bp.outputlist.cleaned[[session]]$bpEstX)==1){
    bp.outputlist.cleaned[[session]]$endTime <- time.output[[session]]
  }
}


# 
# # clean up file names of those studies that have data via RegExp
# for (session in 1:dosdata.numberofstudies){
#   if (length(bp.outputlist.cleaned[[session]]$bpEstX)==1){
#     expression = '\\d\\d\\d\\d_[A-Z][A-Z]_' # Search for ID + 2 lett initials
#     expression2 = '\\d\\d\\d\\d_[A-Z][A-Z][A-Z]_' # ID + 3 letter initials
#     expression3 = '\\d\\d\\d_[A-Z][A-Z]_' # 3 number ID + 2 lett initials
#     expression4 = '_\\d\\d\\d_[A-Z]' # just 2 lett initials
#     
#     # Use expressions sequentially if one doesn't work
#     idx <- regexpr(expression, bp.outputlist.cleaned[[session]]$file)
#     if (idx[1] == -1){
#       idx <- regexpr(expression2, bp.outputlist.cleaned[[session]]$file)
#     }
#     if (idx[1] == -1){
#       idx <- regexpr(expression3, bp.outputlist.cleaned[[session]]$file)
#     }
#     if (idx[1] == -1){
#       idx <- regexpr(expression4, bp.outputlist.cleaned[[session]]$file)
#     }
#     
#     # Remove alphabetic characters and underscores
#     subjectIdentifier = substr(bp.outputlist.cleaned[[session]]$file, idx[1],idx[1]+4)
#     subjectIdentifier = gsub('_','',subjectIdentifier)
#     subjectIdentifier = gsub('[A-Z]','',subjectIdentifier)
#     
#     # Assignment into cleaned output list
#     bp.outputlist.cleaned[[session]]$file <- subjectIdentifier
#   }
#   
# }


# Write to table
seg.out.fid <-  paste("segmentedOutput",dosData.fid,sep="_") # file name

for (session in 1:dosdata.numberofstudies){
  # Column names of first study with data
  if (length(bp.outputlist.cleaned[[session]]) == 8){
    write.table(bp.outputlist.cleaned[[session]],file=seg.out.fid,append=T, sep=",",row.names = F)
    session.start <- session+1
    break
  }
}

for (session in session.start:dosdata.numberofstudies){
  # Continue writing w/o column names starting from last session with full data
  write.table(bp.outputlist.cleaned[[session]],file=seg.out.fid,append=T, sep=",",row.names = F,col.names=F)
}


## Output figures
# Required input - bp.output, a list of segmented outputs, seg.input, a data frame of specified BPs
for(session in 1:dosdata.numberofstudies){
  # If studies have data and are not specified to be uninterperetable
  if (length(bp.output[[session]]$psi)/3 >= 1 && seg.input$specifiedBPs[session] != 0 ){
    
    seg.out.fig.fid <- paste(bp.outputlist.cleaned[[session]]$file,'_',
                             gsub('.csv','',dosData.fid),'.tiff',sep = "")
    
    tiff(seg.out.fig.fid, units = "px", width = 600, height = 600, res = NA, compression = "lzw")
    
    # Plot figures - Use try statements as some data is known to be too
    # noisy to all have breakpoints or successful
    try({bpFigures(bp.output[[session]],time.output[[session]],"Time (min)","Left [HbR] (uM)","PFC HbR")})
    dev.off() 
  }
}