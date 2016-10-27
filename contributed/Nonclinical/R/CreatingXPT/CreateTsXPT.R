####################################################################################
# Script Improvement Ideas:
# > Add correct labels for each column
####################################################################################

####################################################################################
# Functions to Create from ts.xpt files from excel spreadsheet
# See example spreadsheet - it can be expanded with other parameters and any number of studies
# Expects to place output in c:/temp/r testing/xpt output - can be changed with mainDir variable
##################################################################################### Note - had # need Java on windows path to run, for example
#   : C:\Program Files\Java\jdk1.8.0_111\jre\bin\server\
install.packages("XLConnect")
install.packages("SASxport")
require(XLConnect)
require(SASxport)
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
# make copy skipping first row
 df2 = df[-1,]
# for those that are num, transform to numeric
 df2=transform(df2, TSGRPID = as.numeric(TSGRPID))
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
	# place this dataset into a list with a name
	aList = list(studyData)
	# name it
	names(aList)[1]<-"Data"
	# write out dataframe
	write.xport(
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

