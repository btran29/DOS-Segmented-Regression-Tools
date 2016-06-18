# R-code for training data figures
# Brian 6-11-16

# Select data
data <- read.csv("C:/Users/Brian/Dropbox/DOS PFC training/Figures/TrainingSummaryData.csv")

# Load ggplot2
library(ggplot2)

# Figure function
trainingFigure <- function(variable,ylab){
  # Subset data
  subset <- subset(data,Variable == variable)
  
  # Define limits 
  limits <- aes(ymax = Resp + SE, ymin = Resp - SE)
  
  # plot
  p <- ggplot(subset, aes(colour=Training, y=Resp, x=Time))
  p <- p + 
    geom_line(aes(group=Training)) +
    geom_point(aes(group=Training)) +
    geom_errorbar(limits, width=0.2) + 
    xlab("Time Point") +
    ylab(ylab) +
    scale_color_hue() +
    theme(text = element_text(size=20), axis.title.y = element_text(vjust=1))
  
  ggsave(paste(variable,".png",sep=""), plot = last_plot(),
         width = 6, height = 6, units = "in", dpi = 300)
}

trainingFigure("BT","[THb] uM")
trainingFigure("BO","[HbO2] uM")
trainingFigure("PC","PETCO2 (mm Hg)")
trainingFigure("HR","HR (Beats/min)")
trainingFigure("VE","VE (L/min)")
trainingFigure("VCO2","VO2/kg")
trainingFigure("VO2K","VO2 (ml/min/kg)")
trainingFigure("BR","[HbR] uM")
trainingFigure("BS","StO2")