library(SASxport)

load.xpt.files <- function(path=getwd()) {
  # NOTE: this function requries the packages: SASxport and Hmisc
  xptFiles <- list.files(pattern="*.xpt")
  dataFrames <- list()
  count <- 0
  for (xptFile in xptFiles) {
    count <- count + 1
    dataFrames[[count]] <- read.xport(xptFile)
  }
  names(dataFrames) <- tolower(xptFiles)
  return(dataFrames)
}

setwd("C:/Users/Kevin.Snyder/Documents/KronaApp/Public Data/Nimble")

PDSdata <- load.xpt.files()

for (i in seq(length(PDSdata))) {
  name <- paste(PDSdata[[i]][1,'DOMAIN'],'csv',sep='.')
  write.csv(PDSdata[[i]],name,quote=TRUE,row.names = FALSE)
}