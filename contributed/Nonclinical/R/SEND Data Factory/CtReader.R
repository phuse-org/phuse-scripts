### Functions to read and get CT


# Currently available CT Versions
CTVersions <- c(
  "2011-06-10",
  "2011-07-22",
  "2011-12-09",
  "2012-01-02",
  "2012-03-23",
  "2012-08-03",
  "2012-12-21",
  "2013-04-12",
  "2013-06-28",
  "2013-10-04",
  "2013-12-20",
  "2014-03-28",
  "2014-06-27",
  "2014-09-26",
  "2014-12-19",
  "2015-03-27",
  "2015-06-26",
  "2015-09-25",
  "2015-12-18",
  "2016-03-25",
  "2016-06-24",
  "2016-09-30",
  "2016-12-16",
  "2017-03-31",
  "2017-06-30",
  "2017-09-29",
  "2017-12-22",
  "2018-03-30",
  "2018-06-29",
  "2018-09-28",
  "2018-12-21",
  "2019-03-29",
  "2019-06-28",
  "2019-09-27",
  "2019-12-20"
)


## read worksheet by first downloading a file
readWorksheetFromURL <- function(aLocation,aName,aSheet) {
  subdir <- "downloads"
  createOutputDirectory(sourceDir,subdir)
  aTarget <- paste(sourceDir,subdir,aName,sep="/")
  aURL <- paste(aLocation,aName,sep="/")
  # get file if not aleady downloaded
  if (!file.exists(aTarget)) {
    download.file(aURL,aTarget ,mode = "wb")
  }
  readWorksheetFromFile(aTarget,aSheet)
}

## Read in CT file, This should only be called from the getCT function.
importCT <- function(version) {
  
  CTDownloadsDir <- paste0(sourceDir, "/downloads/CT/")
  
  if(file.exists(paste0(CTDownloadsDir, version, ".xls"))) {
    print(paste0("CT Loading... from ",CTDownloadsDir, version, ".xls"))
    df <- readWorksheet(loadWorkbook(paste0(CTDownloadsDir, version, ".xls")), sheet = paste0("SEND Terminology ", version))
  } else {
    print("CT Downloading...")
    # Switch function to determine version
    # Create directory if not there
    createOutputDirectory(sourceDir,"downloads")
    createOutputDirectory(paste0(sourceDir,"/downloads"),"CT")
    # Reads directly from the NCI location
    base <- "https://evs.nci.nih.gov/ftp1/CDISC/SEND/Archive/"
    path <- paste0(base, "SEND%20Terminology%20", version, ".xls")
    print(paste0(CTDownloadsDir, version))
    CTxl <- paste0(CTDownloadsDir, version, ".xls")
    print(paste0("CT Downloading the file... ",path))
    GET(path, write_disk(CTxl),timeout(20))
    df <- readWorksheet(loadWorkbook(CTxl), sheet = paste0("SEND Terminology ", version))
  }
  
  # Attribute used to determine if user changes CT version.
  attr(df, "version") <- version
  
  df
}

# Return CT filtered dataframe, if in parenthesis is the submission value to translate to a codelist name
getCTDF <<- function(codelist, version) {
  
  # If CT hasn't been loaded in already, superassign to parent environment
  if(!exists("CTdf") || !(attr(CTdf, "version") == version)) CTdf <<- importCT(version)
  
  # Remove parenthesis
  parenthesisLoc <- gregexpr(codelist,pattern="[(]")[[1]][1]
  if (parenthesisLoc==1) {
    # starts with a parentheses, so is the code name for a codelist, remove it and find its name
    aValue <- substr(codelist,parenthesisLoc+1,nchar(codelist)-1)
    # find name from submission value
    codelist <- CTdf[(toupper(CTdf$CDISC.Submission.Value) == toupper(aValue)),]$Codelist.Name[1]
  }
  # Return the reqested codelist as a character vector, remove the codelist header row.
  CTdf[(toupper(CTdf$Codelist.Name) == toupper(codelist)) &
         !(is.na(CTdf$Codelist.Code)),]
}

# return a random result from a code list
CTRandomName <<- function(nameList) {
  aSet <- getCTDF(nameList,gCTVersion)
  aRow <- aSet[sample(nrow(aSet), 1), ]
  # return the name
  aRow$CDISC.Submission.Value[1]
}

# return the name given a CT Code number
CTSearchOnCode <<- function(nameList,aCode) {
  
  # print(paste("trying last test code",aCode,nameList))
  aSet <- getCTDF(nameList,gCTVersion)
  # print(paste("tring last test code",aSet))
  aSet[aSet$Code==aCode,]$CDISC.Submission.Value[1]
}


# return the code number given a CT name
CTSearchOnName <<- function(nameList,aName) {
  
  aSet <<- getCTDF(nameList,gCTVersion)
  aSet[aSet$CDISC.Name==aName,]$Codelist.Code[1]
}

# return the code number given a CT short name (submission value)
CTSearchOnShortName <<- function(nameList,aName) {
  
  # print(paste("Retrieving CT code for:",nameList,aName))
  aSet <<- getCTDF(nameList,gCTVersion)
  aSet[aSet$CDISC.Submission.Value==aName,]$Code[1]
}


# get the list for use for a column from the SENDIG
getCodeList <- function(aCol){
  dfSENDIG[dfSENDIG$Column==aCol,]$Codelist[1]
}

# get a test code selection
getSENDTestCode <- function(aCol,aTestCD) {
  # use test code passed in  
  nameList <- getCodeList(aCol)
  if (!is.null(nameList)&& nchar(nameList)>0) {
    lastTestCode <<- CTSearchOnShortName(nameList,aTestCD)
  } else {
    # for some domains, this must come from a configuration file
    aValue <- aTestCD
    lastTestCode <<- aTestCD
  }
  # pass back same set code
  as.character(aTestCD)
}

getSENDLastTestCodeName <- function(aCol,aDomain) {
  # Retrieve from terminology, the test name matching the last test code
  nameList <- getCodeList(aCol)
  if (!is.null(nameList)&& nchar(nameList)>0) {
    aValue <- CTSearchOnCode(nameList,lastTestCode)
    # print(paste("Last test code is ",lastTestCode,aValue))
  } else {
    # some domains, this must come from a configuration file
    print(paste("  Reading test name from code",aDomain,lastTestCode,sep=":"))
    aValue <- getMatchColumn(aDomain,paste0(aDomain,"TESTCD"),lastTestCode,paste0(aDomain,"TEST"))
  }
  aValue
}

