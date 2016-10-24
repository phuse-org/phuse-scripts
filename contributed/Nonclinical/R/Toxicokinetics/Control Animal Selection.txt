# This is sandbox for trying stuff... looking for control animals by looking for animals with a 0 dose
library(SASxport)
source("https://github.com/phuse-org/phuse-scripts/raw/master/contributed/Nonclinical/R/Functions/TK_functions.R")
setwd("C:/PhUSE Script Repository/phuse-scripts/trunk/data/send/PDS/Xpt")
xptdata <- load.xpt.files()
ex=xptdata$ex.xpt
zeroDoseIndex <- which(ex$EXDOSE==0)
controlIDs <- unique(ex$USUBJID[zeroDoseIndex])
