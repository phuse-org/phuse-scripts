####################################################################################
# Script Improvement Ideas:
# > Enable compatibility with .csv as well as .xpt files
# > Handle PCTPTNUM, PCELTM, and PCTP more robustly
# > Handle treatment arms/demographics with more sophistication 
####################################################################################

####################################################################################
# Functions to Create from TK Plotting Script:
# > standardize.days (handles Day 1, Hour 24 vs. Day 2, Hour 24)
# > fix.LOQ.values (handles values below LOQ)
####################################################################################

# Clear All
rm(list=ls())

# check if packages installed and then install if necessary
packages <- c('SASxport','ggplot2','httr')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

# Load required packages
library(SASxport)
library(ggplot2)
library(httr)

# Set variables
LOQrule <- '0' # Set as '0', 'LOQ/2', or 'LOQ'
LOQID <- '[a-zA-Z]'
plotIndividuals <- TRUE
plotAverage <- TRUE
analytes <- 'all' 
days <- 'all'

# Work directly Off of GitHub or locally
useGitHub <- TRUE
GitHubRepo <- 'phuse-org/phuse-scripts'

# Set file/folder locations
baseDirGitHub <- paste('https://github.com',GitHubRepo,'raw/master',sep='/')
baseDirLocal <- path.expand('~/PhUSE/Repo/trunk') # Fill in path to your local copy of the repo
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
  download.GitHub.folder(GitHubRepo,baseDirGitHub,studyDir)
} else {
  path <- paste(baseDirLocal,studyDir,sep='/')
  setwd(path)
  source(paste(baseDirLocal,functionsLocation,sep='/'))
}

# Load data and extract relevant fields and rename them
SENDdata <- load.xpt.files()
rawData <- SENDdata$pc.xpt
SENDfields <- c('USUBJID','PCTEST','PCORRES','VISITDY','PCTPTNUM')
SENDfields_names <- c('Subject','Analyte','Concentration','Day','Hour')
Data <- subTable(SENDfields,SENDfields_names,rawData)

# Add treatments to the dataset
demData <- SENDdata$dm.xpt
keyFields <- c('USUBJID','ARM') # Separate on Trial Sets (to be more robust with respect to recovery, etc.)
keyFields_names <- c('Subject','Treatment')
key <- subTable(keyFields,keyFields_names,demData)
Treatment <- NA
for (i in seq(dim(Data)[1])) {
  name <- as.character(Data$Subject[i])
  nameIndex <- which(key$Subject==name)
  Treatment[i] <- as.character(key$Treatment[nameIndex])
}
Data <- cbind(Data,Treatment)

# Order dataframe logically
Data <- Data[order(Data$Treatment,Data$Subject,Data$Analyte,Data$Day,Data$Hour),]

# Create Function: standardize.days
# Standardize the handling of days/hours
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

# Create Function: fix.LOQ.values
# Fix values below LOQ
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

# Create vectors to loop through
if (days == 'all') {
  days <- sort(unique(Data$Day))
}
if (analytes == 'all') {
  analytes <- unique(Data$Analyte)
}
hours <- unique(Data$Hour)
treatments <- unique(Data$Treatment)

# Create dataset of average values for each treatment group
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

# Plot individual data
if (plotIndividuals == TRUE) {
  for (analyte in analytes) {
    analyteIndex <- which(Data$Analyte==analyte)
    for (day in days) {
      dayIndex <- which(Data$Day==day)
      index1 <- intersect(dayIndex,analyteIndex)
      print(
        ggplot(Data[index1,],aes(x=Hour,y=Concentration,group=Subject,color=Treatment)) +
          geom_line() + geom_point() + 
          ggtitle(paste('Day: ',day,'\n Analyte: ',analyte,sep='')) + labs(x="Hours Postdose",y="Concentration (ng/mL)") +
          theme(title=element_text(size=16),legend.text=element_text(size=16),axis.text=element_text(size=12))
      )
      if (day!=days[length(days)]) {
      } else if (analyte!=analytes[length(analytes)]) {
      }
    }
  }
}

# Plot average data
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
          ggtitle(paste('Day: ',day,'\n Analyte: ',analyte,sep='')) + labs(x="Hours Postdose",y="Concentration (ng/mL)") +
          theme(title=element_text(size=16),legend.text=element_text(size=16),axis.text=element_text(size=12))
      )
      if (day!=days[length(days)]) {
      } else if (analyte!=analytes[length(analytes)]) {
      }
    }
  }
}
