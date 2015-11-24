# Ver 11-22-15 Brian
## DOSI threshold analysis script
# Runs segmented on all CSV studies ending in "Brain_MAT.csv" and "Exe_MAT.csv",
# then outputs the data in a corresponding rawOutput csv file, as well as saves
# segmented plots.

# To run the script on individual subjects, set working directory to input folder,
# then run:
#
# csv <- dir(pattern="*_Brain_MAT.csv")
#
# Type in "csv" to see the file list. Match up indicies with the subject of interest,
# then replace:
#
# for(i in 1:length(csv))
#
# with:
#
# for(i in firstStudyIndex:lastStudyIndex)
#
# where first study index corresponds to the first number in "csv" where the subject
# appears, and the last study index corresponds to the last number in "csv" where
# the subject appears.
#
# Be sure to also set "overlayPlots" to false, as that code assumes that all
# available studies in the input folder to be run.


# Iterations per segmented call
seg.it <- 10

# Make overlay plots? REQUIRES ALL STUDIES TO BE RUN
overlayPlots <- TRUE

# Get working directory for output
workingDir <- getwd()

# Locate files of interest
csv <- dir(pattern="*_Brain_MAT.csv")
csvExe <- dir(pattern="*Exe_MAT.csv")

# Progress bar
pb = winProgressBar(title="DOSI Processing Progress",min = 0, max = 100, initial = 0, width = 300,label="0%")

for(i in 1:length(csv))
{
  # Match with exercise data (based on initial & visit)
  for(iE in 1:length(csvExe)){
    if(substr(csvExe[iE],1,7)==substr(csv[i],1,7)){
      indExe <- iE
    }
  }

  equivExe <- function(studyVisit){
    csvExe = dir(pattern="*Exe_MAT.csv")
    for (iE in 1:length(csvExe)){
      if(studyVisit==substr(csvExe[iE],1,7)){
        indExe <- iE
      }
    }
    return(indExe)
  }

  # Print current study into console (for progress & error tracking)
  cat("======\n")
  cat(paste(substr(csv[i],1,13), "\n"))
  cat(paste(substr(csvExe[indExe],1,11), "\n"))

  # Set progress (for progress & error tracking)
  setWinProgressBar(pb,(i/length(csv)*100),label=sprintf("%g%%",(i/length(csv)*100)))

  # Assign data in file to a data frame after normalizing time
  csvData    <- read.csv(csv[i], header = TRUE)
  csvExeData <- read.csv(csvExe[indExe], header = TRUE)

  Time     <- csvData[[1]]
  normTime <- Time-min(Time)
  exeTime  <- csvExeData[[1]]

  BO  <- data.frame(x=normTime, y=csvData[[2]])
  BR  <- data.frame(x=normTime, y=csvData[[3]])
  BT  <- data.frame(x=normTime, y=csvData[[4]])
  BS  <- data.frame(x=normTime, y=csvData[[5]])
  BOf <- data.frame(x=normTime, y=csvData[[6]])
  BRf <- data.frame(x=normTime, y=csvData[[7]])
  BTf <- data.frame(x=normTime, y=csvData[[8]])
  BSf <- data.frame(x=normTime, y=csvData[[9]])
  SC1 <- data.frame(x=normTime, y=csvData[[10]])
  SC2 <- data.frame(x=normTime, y=csvData[[11]])
  SC3 <- data.frame(x=normTime, y=csvData[[12]])
  AC1 <- data.frame(x=normTime, y=csvData[[13]])
  AC2 <- data.frame(x=normTime, y=csvData[[14]])
  AC3 <- data.frame(x=normTime, y=csvData[[15]])
  PL1 <- data.frame(x=normTime, y=csvData[[16]])
  PL2 <- data.frame(x=normTime, y=csvData[[17]])
  PL3 <- data.frame(x=normTime, y=csvData[[18]])

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

  # Convert data of interest to a linear model for segmented input
  out <-list(
    "oBO"  = lm.BO  <- lm(y~x,data=BO),
    "oBR"  = lm.BR  <- lm(y~x,data=BR),
    "oBT"  = lm.BT  <- lm(y~x,data=BT),
    "oBS"  = lm.BS  <- lm(y~x,data=BS),
    "oBOf" = lm.BOf <- lm(y~x,data=BOf),
    "oBRf" = lm.BRf <- lm(y~x,data=BRf),
    "oBTf" = lm.BTf <- lm(y~x,data=BTf),
    "oBSf" = lm.BSf <- lm(y~x,data=BSf),
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

  # Exception: 1p segmented function for LiFi
  DOSI.segmented.Lifi <- function(var,arg2){
    try({
      varOut <- segmented(var,seg.Z=~x,psi=list(x=7),control=seg.control(display=FALSE,n.boot=50, it.max=seg.it))
    })
    return(varOut)
  }

  # Check and remove previous study's output to prevent overwriting of data during csv/fig output
  if(exists("bpOutput")==TRUE){rm(bpOutput)}

  # Exceptions: 2p method for AuLi, ErSc, TyCo,YaAl, 1p method for LiFi V6
  if(any(substr(csv[i],1,4)==c("AuLi","ErSc","TyCo","YaAl","LiFi"))==TRUE){
    cat(paste("Using 2 points method","\n"))
    try({
      if(substr(csv[i],1,4)==c("AuLi")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=7,simplify=FALSE,USE.NAMES=TRUE)}
      if(substr(csv[i],1,4)==c("ErSc")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=7,simplify=FALSE,USE.NAMES=TRUE)}
      if(substr(csv[i],1,4)==c("TyCo")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=6,simplify=FALSE,USE.NAMES=TRUE)}
      if(substr(csv[i],1,4)==c("YaAl")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=6,simplify=FALSE,USE.NAMES=TRUE)}
      if(substr(csv[i],1,7)==c("LiFi_V6")){bpOutput <- sapply(out,DOSI.segmented.Lifi,simplify=FALSE,USE.NAMES=TRUE)}
      if (exists("bpOutput")==FALSE){cat("Reverting to automatic breakpoint selection \n")}
    })
  }

  # >=5 breakpoint Exceptions: From running script once and checking for 5 HbR breakpoints in brain data; apply 2p method, using judgement
  if(any(substr(csv[i],1,4)==c("AmDa","AnGo"))==TRUE){
    cat(paste("Using 2 points method for studies with >5 HbR breakpoints","\n"))
    try({
      if(substr(csv[i],1,4)==c("AmDa")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=7,simplify=FALSE,USE.NAMES=TRUE)}
      if(substr(csv[i],1,4)==c("AnGo")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=5,arg3=9,simplify=FALSE,USE.NAMES=TRUE)}
      # Exception to >=5 breakpoint restriction: one-off as noted by Goutham
      # if(substr(csv[i],1,4)==c("ShBa")){bpOutput <- sapply(out,DOSI.segmented,twopoints=TRUE,arg2=3,arg3=7,simplify=FALSE,USE.NAMES=TRUE)}
    })
  }

  # Run segmented
  # Revert to automatic breakpoint selection if 2p doesn't work with estimated breakpoints; raw segmented method for all other studies
  if (exists("bpOutput")==FALSE){bpOutput <- sapply(out,DOSI.segmented,twopoints=FALSE,simplify=FALSE,USE.NAMES=TRUE)}

  # Mark to use 2p if raw HbR results in >= 5breakpoints
  fivebreakpoints <- FALSE
  if(length(bpOutput$oBR$psi[,2])>=5){
    fivebreakpoints <- TRUE
    cat(paste(">=5 HbR breakpoints found","\n"))
  } # if(isTRUE(fivebreakpoints)==TRUE){}

  # Get base file name for outputs
  outputFileName <- paste(workingDir,"/rawOut_",paste(substr(csv[i],1,13)),"_", sep="")

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
    write.table(paste(names(bpOutput)[ibpOutput],substr(csv[i],1,13)),
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
  write.table(paste(substr(csv[i],1,4),"Maximum work-rate data",sep=" "),
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

} # End of length(csv) loop for initial segmented calls + plotting

## After initial data collection is complete,

# Make overlay plots
if(overlayPlots){
# Requires ExeDOSI global nested list variable

# Locate files of interest
csv <- dir(pattern="*_Brain_MAT.csv")
csvExe <- dir(pattern="*Exe_MAT.csv")

# Set up data collection and plotting functions


ggOverlayPlot <- function(variable,var1lab,variable2,var2lab,gYlab,gTitle){
  ## collect data for ggplot

  # In the case of no breakpoints
  nobreakpoint <- (any(variable$psi[1,2]==0) | any(variable2$psi[1,2]==0))

  if(nobreakpoint){
    df <- data.frame()
    p  <- ggplot(df)+
      geom_point()+
      geom_blank()+
      labs(x="Time (min)",y=gYlab,title=gTitle)+
      scale_x_continuous(breaks=0:12,limits=c(-.5,12.5))+
      scale_y_continuous(limits=c(1,50))+
      theme_bw()+
      theme(plot.title = element_text(lineheight=.8, face="bold")
            , axis.line = element_line(size=.7, color = "black")
      )+
      annotate("text", x = 6, y = 25, label = "Missing Data", color = "black", alpha =.5)
  }

  if(!nobreakpoint){
    # Dataframes for points and segmented line
    ggplotOverlayDFpoints <- function(variable,varLab){
      df <- data.frame(study=factor(varLab),
                       x=variable$model$x,
                       y=variable$model$y,
                       segmented=variable$fitted.values)
      return(df)
    }

    # Dataframes for breakpoint points and confint
    ggplotOverlayDFbreakpoints <- function(variable,varLab){
      # Get W from associated exe for collectBPdata function
      exeTime  <- Figure.csvData.EXE[[1]]
      # Use collectBPdata function to get confint data
      df.lab <- data.frame(study=factor(varLab))
      df <- collectBPdata(variable)
      df <- merge(df,df.lab)
      return(df)
    }

    # Collect the rest of the data
    mergeStudyData <- function(variable,var1lab,variable2,var2lab,type){
      if(type=="raw"){
        df1    <- ggplotOverlayDFpoints(variable,var1lab)
        df2    <- ggplotOverlayDFpoints(variable2,var2lab)
        df     <- rbind(df1,df2)
      } else if(type=="bp"){
        df1.bp <- ggplotOverlayDFbreakpoints(variable,var1lab)
        df2.bp <- ggplotOverlayDFbreakpoints(variable2,var2lab)
        df  <- rbind(df1.bp,df2.bp)
      }
      return(df)
    }

    # Collect Data
    df    <- mergeStudyData(variable,var1lab,variable2,var2lab,type="raw")
    df.bp <- mergeStudyData(variable,var1lab,variable2,var2lab,type="bp")

    # Due to a bug in ggplot2 regarding error bar height, will be using a factor to correct
    errbarHeight <- .15*2.7^(.0058*length(df$x))

    # Plot graph with ggplot2
    p <- ggplot(df.bp,(aes(x=bpEstX,y=bpEstY)))+
      # Labels
      labs(x="Time (min)",y=gYlab,title=gTitle)+
      scale_color_discrete(name="Study Visit",h.start=15,direction=1)+
      scale_x_continuous(breaks=0:12,limits=c(-.5,12.5))+

      # Raw data points
      geom_point(data=df,aes(x=x,y=y,colour=factor(study)))+

      # Attempt to plot segmented data
      geom_line(data=df,aes(x=x,y=segmented,colour=factor(study)),size=1)+
      # geom_line(data=df,aes(x=x,y=segmented,linetype=factor(study)),size=.5, color="white")+

      # Overlay breakpoint data
      geom_errorbarh(data=df.bp,(aes(xmax=uConf,xmin=lConf)),color="black",height=errbarHeight)+
      geom_vline(data=df.bp,aes(xintercept=bpEstX, linetype=factor(study)),size=.8,alpha=1)+
      geom_point(data=df.bp,aes(y=bpEstY,x=bpEstX,colour=factor(study)),size=5.5)+
      geom_point(data=df.bp,aes(y=bpEstY,x=bpEstX,colour=factor(study)),size=4,shape=21,fill="white")+

      # Change chart theme
      theme_bw()+
      theme(plot.title = element_text(lineheight=.8, face="bold")
            , axis.line = element_line(size=.7, color = "black")
      )
  }
  return(p)
} # End of ggplot function

## Plot tiling function
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  numPlots = length(plots)
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  if (numPlots==1) {
    print(plots[[1]])
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

# Start collection and plotting
for(i in 1:length(csv))
  {

  # Remove previous indexing variables, if present
  if(exists("indPostTraining")==TRUE){
    rm(indPostTraining)
  }
  if(exists("indPostTrainingExe")==TRUE){
    rm(indPostTrainingExe)
  }

  # Collect corresponding pre or post-training data for overlay figure plotting
  isV1 <- substr(csv[i],6,13)=="V1_Brain"
  isV3 <- substr(csv[i],6,13)=="V3_Brain"

  if(isV1 | isV3 ){

    for(iPostTraining in 1:length(csv)){

      # If a matching V4 or V6 study is found
      matchingV4 <- substr(csv[iPostTraining],1,13) == paste(substr(csv[i],1,5),"V4_Brain",sep="")
      matchingV6 <- substr(csv[iPostTraining],1,13) == paste(substr(csv[i],1,5),"V6_Brain",sep="")
      if(matchingV4 | matchingV6){

        # Mark study
        indPostTraining <- iPostTraining

        # Mark location of either a relate V4 or V6 exercise study for collectbpData function
        # Can be extended for overlaying exercise related data
        for(iPostTrainingExe in 1:length(csvExe)){
          matchingv4Exe <- substr(csvExe[iPostTrainingExe],1,11) == paste(substr(csv[indPostTraining],1,7),"_Exe",sep = "")
          matchingv6Exe <- substr(csvExe[iPostTrainingExe],1,11) == paste(substr(csv[indPostTraining],1,7),"_Exe",sep = "")
          if(exists("indPostTrainingExe") == FALSE){indPostTrainingExe <- vector(mode="numeric", length=1)}
          if(matchingv4Exe){indPostTrainingExe <- iPostTrainingExe}
          if(matchingv6Exe){indPostTrainingExe <- iPostTrainingExe}

        }

        # Load post-training equilvalent marked study from ExeDOSI global variable
        Figure.csvData.POST <- ExeDOSI[[indPostTraining]][[1]]

        # Load pre-training data from ExeDOSI global variable
        Figure.csvData.PRE  <- ExeDOSI[[i]][[1]]

        # Load associated post-training exercise data (for collectbpData function)
        Figure.csvData.EXE   <- read.csv(csvExe[indPostTrainingExe[1]], header = TRUE)

        # Get base file name for outputs
        outputFileName <- paste(workingDir,"/rawOut_",substr(csv[i],1,4),"_",substr(csv[i],6,7),substr(csv[indPostTraining],6,7), sep="")

        # Collect current study data for plotting function
        var1lab <- "Pre Training"  #substr(csv[i],6,7)
        var2lab <- "Post Training" #substr(csv[indPostTraining],6,7)

        # Plot overlay figure
        p1 <- ggOverlayPlot(Figure.csvData.PRE$oBR,var1lab,Figure.csvData.POST$oBR,var2lab,"[HBR] (µM)","PFC HbR")
        p2 <- ggOverlayPlot(Figure.csvData.PRE$oBS,var1lab,Figure.csvData.POST$oBS,var2lab,"stO2 (µM)","PFC stO2")

        pdf(file = paste(outputFileName,"BRBS.pdf",sep=""))
        multiplot(p1,p2,cols=1)
        dev.off()

        p3 <- ggOverlayPlot(Figure.csvData.PRE$oBO,var1lab,Figure.csvData.POST$oBO,var2lab,"HbO2 (µM)","PFC HbO2")
        try({p4 <- ggOverlayPlot(Figure.csvData.PRE$oBT,var1lab,Figure.csvData.POST$oBT,var2lab,"THb (µM)","PFC THb")})

        pdf(file = paste(outputFileName,"BOBT.pdf",sep=""))
        multiplot(p3,p4,cols=1)
        dev.off()

        p5 <- ggOverlayPlot(Figure.csvData.PRE$oVE,var1lab,Figure.csvData.POST$oVE,var2lab,"VE (L/min)","VE")
        p6 <- ggOverlayPlot(Figure.csvData.PRE$oPC,var1lab,Figure.csvData.POST$oPC,var2lab,"PETCO2 (mmHg)","PETCO2")

        pdf(file = paste(outputFileName,"VEPC.pdf",sep=""))
        multiplot(p5,p6,cols=1)
        dev.off()

        p7 <- ggOverlayPlot(Figure.csvData.PRE$oHR,var1lab,Figure.csvData.POST$oHR,var2lab,"Heart Rate (beats/min)","Heart Rate")
        p8 <- ggOverlayPlot(Figure.csvData.PRE$oBOf,var1lab,Figure.csvData.POST$oBOf,var2lab,"HbO2 FAC (µM)","PFC HbO2 FAC")

        pdf(file = paste(outputFileName,"HRBOf.pdf",sep=""))
        multiplot(p7,p8,cols=1)
        dev.off()

        # Landscape HbR
        pdf(file = paste(outputFileName,"HbR.pdf",sep=""), height = 3.5, width = 7)
        multiplot(p1,cols=1)
        dev.off()
      }
    }
    if(exists("indPostTraining")==T){
      # For troubleshooting script
      cat(paste("==== \n Studies used: \n",csv[i],"\n",csv[indPostTraining],"\n",csvExe[indPostTrainingExe],"\n"))
      cat(paste(" i = ",i,"; indPostTraining = ",indPostTraining,"; indPostTrainingExe = ",indPostTrainingExe,"\n",sep=""))
    }
  }
} # End of length(csv) loop

} # End of overlayplots "if" statement
