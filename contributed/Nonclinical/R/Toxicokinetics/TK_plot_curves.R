# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('foreign','ggplot2')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

# Load Required Libraries
library(SASxport)
library(ggplot2)
library(curl)

# Set Variables
LOQrule <- '0' # Set as '0', 'LOQ/2', or 'LOQ'
LOQID <- '[a-zA-Z]'
plotIndividuals <- FALSE
plotAverage <- TRUE
analytes <- 'all' 
days <- 'all'

# Work Online or Offline
online <- TRUE

# Set File Locations
baseDirOnline <- 'https://github.com/phuse-org/phuse-scripts/raw/master/data/send'
baseDirOffline <- 'C:/Users/Kevin.Snyder/Documents/PhUSE/SEND/Dataset'
studyDir <- 'instem/Xpt'
onlineWD <- 'c:/Users/Kevin.Snyder/Documents/Temp' # NOTE: use a temp directory because all files in this directory will be deleted at start of this script

if (online == TRUE) {
  path <- paste(baseDirOnline,studyDir,sep='/')
  setwd(onlineWD)
  file.remove(list.files()) # !!! Deleting all files in temp directory !!!
} else {
  path <- paste(baseDirOffline,studyDir,sep='/')
  setwd(path)
}

# Load Data and Extract Relevant Fields and Rename Them
if (online == TRUE) {
  suppressWarnings(try(download.file(paste(path,'PC.xpt',sep='/'),'PC.xpt',mode='wb'),silent=TRUE))
  suppressWarnings(try(rawData <- read.xport('PC.xpt'),silent=TRUE))
  
  suppressWarnings(try(download.file(paste(path,'pc.xpt',sep='/'),'PC.xpt',mode='wb'),silent=TRUE))
  suppressWarnings(try(rawData <- read.xport('PC.xpt'),silent=TRUE))
} else {
  rawData <- read.xport('PC.xpt')
}
SENDfields <- c('USUBJID','PCTEST','PCORRES','VISITDY','PCTPTNUM')
count <- 0
colIndex <- NA
for (field in SENDfields) {
  count <- count + 1
  index <- which(colnames(rawData)==field)
  colIndex[count] <- index
}
Data <- rawData[,colIndex]
colnames(Data) <- c('Subject','Analyte','Concentration','Day','Hour')

# Add Treatments to Dataset
if (online == TRUE) {
  suppressWarnings(try(download.file(paste(path,'DM.xpt',sep='/'),'DM.xpt',mode='wb'),silent=TRUE))
  suppressWarnings(try(demData <- read.xport('DM.xpt'),silent=TRUE))
  
  suppressWarnings(try(download.file(paste(path,'dm.xpt',sep='/'),'DM.xpt',mode='wb'),silent=TRUE))
  suppressWarnings(try(demData <- read.xport('DM.xpt'),silent=TRUE))
} else {
  demData <- read.xport('DM.xpt')
}
keyFields <- c('USUBJID','ARM')
count <- 0
keyIndex <- NA
for (field in keyFields) {
  count <- count + 1
  index <- which(colnames(demData)==field)
  keyIndex[count] <- index
}
key <- demData[,keyIndex]
colnames(key) <- c('Subject','Treatment')
Treatment <- NA
for (i in seq(dim(Data)[1])) {
  name <- as.character(Data$Subject[i])
  nameIndex <- which(key$Subject==name)
  Treatment[i] <- as.character(key$Treatment[nameIndex])
}
Data <- cbind(Data,Treatment)

# Order Dataframe Logically
Data <- Data[order(Data$Treatment,Data$Subject,Data$Analyte,Data$Day,Data$Hour),]

# Standardize Days
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
