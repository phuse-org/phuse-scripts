# This is sandbox for trying stuff... looking for control animals by looking for animals with a 0 dose
library(SASxport)
source("https://github.com/phuse-org/phuse-scripts/raw/master/contributed/Nonclinical/R/Functions/Functions.R")
# setwd("C:/PhUSE Script Repository/phuse-scripts/trunk/data/send/PDS/Xpt")
setwd("C:/Users/Kevin.Snyder/Documents/PhUSE/Repo/trunk/data/send/PDS/Xpt")
xptdata <- load.xpt.files()
ex <- xptdata$ex
zeroDoseIndex <- which(ex$EXDOSE==0)
controlIDs <- unique(ex$USUBJID[zeroDoseIndex])

domain <- "lb.xpt"
domainData <- xptdata[domain][[1]]

subjectIndex <- which(domainData$USUBJID%in%controlIDs)

test <- c("RBC")
testIndex <- which(domainData$LBTESTCD%in%test)

testCats <- c("HEMATOLOGY")
testCatIndex <- which(domainData$LBCAT%in%testCat)

testSpec <- c("WHOLE BLOOD")
testSpecIndex <- which(domainData$LBSPEC%in%testSpec)

indexTmp <- intersect(testIndex,testCatIndex)
index <- intersect(testSpecIndex,indexTmp)

controlTestIndex <- intersect(subjectIndex,index)
counts <- domainData$LBORRES[controlTestIndex]

countsN <- as.numeric(counts)
countsNumber <- as.numeric(levels(counts)[countsN])

print(paste("Mean Control ",test," Count: ",mean(as.numeric(countsNumber)),sep=''))