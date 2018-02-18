###############################################################################
# Functions to Create from ts.xpt files from excel spreadsheet
# See example spreadsheet - it can be expanded with other parameters and any number of studies
# Expects to place output in subdirectories of the location of the XLS file selected
####################################################################################
# XLConnect documentation here:
# https://cran.r-project.org/web/packages/XLConnect/vignettes/XLConnect.pdf
# SASxport documentation here:
# https://cran.r-project.org/web/packages/SASxport/SASxport.pdf
####################################################################################
# You may need next two lines first time
# install.packages("XLConnect")
# install.packages("SASxport")
####################################################################################
require(XLConnect)
require(SASxport)
require(utils)
if(packageVersion("SASxport") < "1.5.7") {
  stop("You need version 1.5.7 or later of SASxport")
}
# This section is to replace functions in 1.5.7 or SASxport to allow column lengths of less than 8 bytes
# This gives the directory of the file where the statement was placed , to get current .R script directory
 sourceDir <- getSrcDirectory(function(dummy) {dummy})
 source(paste(sourceDir, "/write.xport2.R", sep=""))
 tmpfun <- get("read.xport", envir = asNamespace("SASxport"))
 environment(write.xport2) <- environment(tmpfun)
 attributes(write.xport2) <- attributes(tmpfun)
 assignInNamespace("write.xport", write.xport2, ns="SASxport")
# Select file to read, will place output in subdirectories of that
# Set output files
myFile <- choose.files(caption = "Select XLS file",multi=F,filters=cbind('.xls or xlsx files','*.xls;*.xlsx'))
mainDir <- dirname(myFile)
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
	studyData <- subset(df2, STUDYID==aStudy,keepNA=FALSE)
	# Set length for character fields
	SASformat(studyData$DOMAIN) <-"$2."	
	# place this dataset into a list with a name
	aList = list(studyData)
	# name it
	names(aList)[1]<-"TS"
	# and label it
	attr(aList,"label") <- "TRIAL SUMMARY"
	# write out dataframe
	write.xport2(
		list=aList,
		file = "ts.xpt",
		verbose=FALSE,
		sasVer="7.00",
		osType="R 3.4.2",	
		cDate=Sys.time(),
		formats=NULL,
		autogen.formats=TRUE
	)
	aLine <- paste("Created file:  ", mainDir, "/",aStudy,"/ts.xpt",sep = "")
	print(aLine)
}  # end of study loop
setwd(mainDir)
