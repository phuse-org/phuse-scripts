# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('SASxport','ggplot2','httr')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

# Load Required Libraries
library(SASxport)
library(ggplot2)
library(httr)

# Set Variables
LOQrule <- '0' # Set as '0', 'LOQ/2', or 'LOQ'
LOQID <- '[a-zA-Z]'
plotIndividuals <- FALSE
plotAverage <- TRUE
analytes <- 'all' 
days <- 'all'

# Work Directly Off of GitHub or Locally
useGitHub <- TRUE
GitHubRepo <- 'phuse-org/phuse-scripts'

# Set File/Folder Locations
baseDirGitHub <- paste('https://github.com',GitHubRepo,'raw/master',sep='/')
baseDirLocal <- path.expand('~/PhUSE/Repo/trunk')
studyDir <- 'data/send/PDS/Xpt'
functionsLocation <- 'contributed/Nonclinical/R/Functions/TK_functions.R'
tmpPath <- path.expand('~/Temp_R_Working_Directory') # All files in this directory will be deleted!

# Set working directory and source functions
if (useGitHub == TRUE) {
  source(paste(baseDirGitHub,functionsLocation,sep='/'))
  if (dir.exists(tmpPath)==FALSE) {
    dir.create(tmpPath)
  }
  setwd(tmpPath)
  file.remove(list.files())
  downloadGitHubFolder(GitHubRepo,baseDirGitHub,studyDir)
} else {
  path <- paste(baseDirLocal,studyDir,sep='/')
  setwd(path)
  source(paste(baseDirLocal,functionsLocation,sep='/'))
}

# Load Data and Extract Relevant Fields and Rename Them
SENDdata <- loadXPTfiles()
rawData <- SENDdata$pc.xpt
SENDfields <- c('USUBJID','PCTEST','PCORRES','VISITDY','PCTPTNUM')
SENDfields_names <- c('Subject','Analyte','Concentration','Day','Hour')
Data <- createData(SENDfields,SENDfields_names,rawData)


# !!! Check that PCTPTNUM may not actually be hour !!!
# Parse PCELTM (look for R library to do this)
# https://cran.r-project.org/web/packages/parsedate/
# !!! Try PCELTM first but if doesn't exist then use PCTPTNUM !!!


# Add Treatments to Dataset
demData <- SENDdata$dm.xpt
keyFields <- c('USUBJID','ARM') # Separate on Trial Sets (to be more robust with respect to recovery, etc.)
keyFields_names <- c('Subject','Treatment')
key <- createData(keyFields,keyFields_names,demData)

# Merge Relevant PC.xpt and DM.xpt Fields
Treatment <- NA
for (i in seq(dim(Data)[1])) {
  name <- as.character(Data$Subject[i])
  nameIndex <- which(key$Subject==name)
  Treatment[i] <- as.character(key$Treatment[nameIndex])
}
Data <- cbind(Data,Treatment)

### Left of here on 7/14/16

# Order Dataframe Logically
Data <- Data[order(Data$Treatment,Data$Subject,Data$Analyte,Data$Day,Data$Hour),]

# Standardize Days !!!! document how the data was treated !!!!! left off here on 8/18/16
# write this into a function
subjects <- unique(Data$Subject)
for (subject in subjects) {
  index <- which(Data$Subject==subject)
  l24index <- which(Data$Hour[index] < 24)
  g24index <- which(Data$Hour[index] >= 24)
  if (length(g24index > 0)) {
    for (item in g24index) {
      today <- Data$Day[index][max(which(l24index<item))]
      Data$Day[index][item] <- today
    }
  }
}  

# Deal with Values Below LOQ
Data$Concentration <- as.character(Data$Concentration)
stringConc <- Data$Concentration
index <- grep(LOQID,Data$Concentration)
if (length(index) > 0) {
  if (LOQrule == '0') {
    Data$Concentration[index] <- '0'
  } else {
    for (i in index) {
      if (is.finite(rawData$PCLLOQ[i])) {
        Data$Concentration[i] <- rawData$PCLLOQ[i]
      } else {
        Data$Concentration[i] <- regmatches(stringConc[i],regexpr("[[:digit:]]+",stringConc[i]))
      }
    }
  }
}
Data$Concentration <- as.numeric(Data$Concentration)
if (LOQrule == 'LOQ/2') {
  Data$Concentration[index] <- Data$Concentration[index]/2
}

# Create Sets of Factors
if (days == 'all') {
  days <- sort(unique(Data$Day))
}
if (analytes == 'all') {
  analytes <- unique(Data$Analyte)
}
hours <- unique(Data$Hour)
treatments <- unique(Data$Treatment)

# Create Average Data
avgData <- rep(NA,length(analytes)*length(treatments)*length(days)*length(hours)*6)
dim(avgData) <- c(length(analytes)*length(treatments)*length(days)*length(hours),6)
colnames(avgData) <- c('Analyte','Treatment','Day','Hour','Concentration','SE')
count <- 0
for (analyte in analytes) {
  for (treatment in treatments) {
    for (day in days) {
      for (hour in hours) {
        count <- count + 1
        index <- which((Data$Analyte==analyte)&(Data$Treatment==treatment)&(Data$Day==day)&(Data$Hour==hour))
        avgConc <- mean(Data$Concentration[index],na.rm=TRUE)
        sdConc <- sd(Data$Concentration[index],na.rm=TRUE)
        seConc <- sdConc/sqrt(length(which(is.finite(Data$Concentration[index])==1)))
        avgData[count,] <- c(analyte,treatment,day,hour,avgConc,seConc)
      }
    }
  }
}
avgData <- as.data.frame(avgData,stringsAsFactors=FALSE)
avgData$Day <- as.numeric(avgData$Day)
avgData$Hour <- as.numeric(avgData$Hour)
avgData$Concentration <- as.numeric(avgData$Concentration)
avgData$SE <- as.numeric(avgData$SE)
finiteIndex <- which(is.finite(avgData$Concentration))
avgData <- avgData[finiteIndex,]

# Plot Individual Data
if (plotIndividuals == TRUE) {
  for (analyte in analytes) {
    analyteIndex <- which(Data$Analyte==analyte)
    for (day in days) {
      dayIndex <- which(Data$Day==day)
      index1 <- intersect(dayIndex,analyteIndex)
      print(
        ggplot(Data[index1,],aes(x=Hour,y=Concentration,group=Subject,color=Treatment)) +
          geom_line() + geom_point() + 
          ggtitle(paste('Day: ',day,'\n Analyte: ',analyte,sep=''))
      )
      if (day!=days[length(days)]) {
      } else if (analyte!=analytes[length(analytes)]) {
      }
    }
  }
}

# Plot Average Data
if (plotAverage == TRUE) {
  for (analyte in analytes) {
    analyteIndex <- which(avgData$Analyte==analyte)
    for (day in days) {
      dayIndex <- which(avgData$Day==day)
      index1 <- intersect(dayIndex,analyteIndex)
      limits <- aes(ymax = avgData$Concentration[index1] + avgData$SE[index1], ymin = avgData$Concentration[index1] - avgData$SE[index1])
      print(
        ggplot(avgData[index1,],aes(x=Hour,y=Concentration,group=Treatment,color=Treatment)) +
          geom_line() + geom_point() + geom_errorbar(limits,width=1) + xlim(0,max(Data$Hour)) +
          ggtitle(paste('Day: ',day,'\n Analyte: ',analyte,sep=''))
      )
      if (day!=days[length(days)]) {
      } else if (analyte!=analytes[length(analytes)]) {
      }
    }
  }
}
