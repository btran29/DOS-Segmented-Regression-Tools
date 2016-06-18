directory	<- dir(pattern="*Exe MAT Binned.csv")

# Set up collection variable
maxHRvalues = vector(mode = "numeric", length = length(directory))


# Loop over all files in directory
for (isession in 1:length(directory)){
  # Read file
  session = read.csv(directory[isession])
  
  # Get Max Value
  # Save to collection variable
  maxHRvalues[isession] = max(session$HR)
  
}

test = cbind(directory,maxHRvalues)
write.table(test,
            "Data.csv", sep=",", append=TRUE,
            row.names=FALSE)