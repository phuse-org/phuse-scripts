
####################################################################################
# Functions to Create from ts.xpt files from excel spreadsheet
# See example spreadsheet - it can be expanded with other parameters and any number of studies
# Expects to place output in c:/temp/r testing/xpt output - can be changed with mainDir variable
####################################################################################
# Setup instructions
# You need Java on windows path to run, for example
#   : C:\Program Files\Java\jdk1.8.0_111\jre\bin\server\
#   If running R-64bit, ensure you are also running Java 64-bit
####################################################################################
# XLConnect documentation here:
# https://cran.r-project.org/web/packages/XLConnect/vignettes/XLConnect.pdf
# SASxport documentation here:
# https://cran.r-project.org/web/packages/SASxport/SASxport.pdf
####################################################################################
# Improvements to make
#    TSGRPID if empty should be set to 1 character length
#    Could use file chooser result directory to use for output location
####################################################################################
# You may need next two lines first time
# install.packages("XLConnect")
# install.packages("SASxport")
####################################################################################
require(XLConnect)
require(SASxport)
# Here is temporary override of write xport function to get desired minimum variable lengths.
# Use environment for other function in package to allow use of unexported functions in package
	source("c:/temp/r testing/write.xport2.R")
	tmpfun <- get("read.xport", envir = asNamespace("SASxport"))
	environment(write.xport2) <- environment(tmpfun)
	attributes(write.xport2) <- attributes(tmpfun)
	assignInNamespace("write.xport", write.xport2, ns="SASxport")
# Select file to read
mainDir <- "c:/temp/r testing/xpt output"
# Set output files
setwd(mainDir)
myFile <- file.choose()
# Read in XLSX file
df <- readWorksheetFromFile(myFile,
                            sheet=1,
                            startRow = 1,
                            endCol = 7)
# make copy skipping first two rows (field type and field label)
 df2 = df[-1,]
 df2 = df2[-1,]
# for those that are num, transform to numeric
  df2=transform(df2, TSSEQ = as.numeric(TSSEQ))
# set labels for each field 
  Hmisc::label(df2)=df[2,]
# For each set of rows belonging to a study create TS.XPT file
studyList <- unique(df2$STUDYID)
for(aStudy in studyList){
	# Create subdirectory
	# Set output files
	setwd(mainDir)
	if (file.exists(aStudy)){
	    setwd(file.path(mainDir, aStudy))
	} else {
	    dir.create(file.path(mainDir, aStudy))
	    setwd(file.path(mainDir, aStudy))
	}
	# filter to this study
	studyData <- subset(df2, STUDYID==aStudy)
	# Set length for character fields
	SASformat(studyData$DOMAIN) <-"$2."	
	# place this dataset into a list with a name
	aList = list(studyData)
	# name it
	names(aList)[1]<-"Data"
	# write out dataframe
	write.xport2(
		list=aList,
		file = "ts.xpt",
		verbose=FALSE,
		sasVer="7.00",
		osType="R 3.0.1",	
		cDate=Sys.time(),
		formats=NULL,
		autogen.formats=TRUE
	)
	aLine <- paste("Created file:  ", mainDir, "/",aStudy,"/ts.xpt",sep = "")
	print(aLine)
}  # end of study loop
setwd(mainDir)

