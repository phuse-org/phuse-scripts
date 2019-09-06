####################################################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Function Ideas !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
####################################################################################


# > standardize.days (handles Day 1, Hour 24 vs. Day 2, Hour 24)


# > fix.LOQ.values (handles values below LOQ)


# > check.define.xml (checks define.xml against .xpt files present)


# > subset.list (isolate rows from all tables in a list corresponding to subjects with a particular demographic characteristic)
# > subset.table (isolate rows in table corresponding to subjects with a particular demographic characteristic)
# > subset.column (isolate rows in column corresponding to subjects with a particular demographic characteristic)


# EXAMPLE: select all data from control animals
#   How to deal with multiple treatments (combination product)?
#       There is an optional shortcut for this but may not be included in all datasets
#   Take general approach:
#       (1) in dm.xpt identify SETCD
#       (2) in tx.xpt use SETCD to get the Value in TXPARMCD (i.e. TCNTRL)
#   
#   Or use ex.xpt approach



# EXAMPLE: select all data collected before a particular date
# How to account for cage level linking with subjects?
# Identify nesting structures (nestings may overlap)

# Is it possible to read xpt files into dataframes without downloading the .xpt file?

# > write.xpt (write .xpt file from R data frame)


# > SEND.to.xls (write an excel file with all .xpt files as different tabs or single files with a description tab)


####################################################################################



####################################################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!! Working Functions !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
####################################################################################


# Function to download all files from a GitHub folder
# NOTE: this function requires the package: "httr"
download.GitHub.folder <- function (
    GitHubRepo="phuse-org/phuse-scripts"
  , baseDirGitHub="https://github.com/phuse-org/phuse-scripts/raw/master"
  , studyDir="data/send/PDS/Xpt") {
  req <- GET(paste('https://api.github.com/repos',GitHubRepo,'contents',studyDir,sep='/'))
  contents <- content(req,as='parsed')
  for (i in seq(length(contents))) {
    filePath <- contents[[i]]$path
    download.file(paste(baseDirGitHub,filePath,sep='/'),basename(filePath),mode='wb')
  }
}

# Function to list all files from a GitHub folder
# NOTE: this function requires the packages: "httr", "Hmisc" and "tools"
load.GitHub.xpt.files <- function (
  GitHubRepo="phuse-org/phuse-scripts",
  baseDirGitHub="https://github.com/phuse-org/phuse-scripts/raw/master",
  studyDir="data/send/PDS/Xpt",
  domainsOfInterest=NULL,showProgress=F,
  authenticate=FALSE,User=NULL,Password=NULL) {
  if (authenticate==TRUE) {
    req <- GET(paste('https://api.github.com/repos',GitHubRepo,'contents',studyDir,sep='/'),
               authenticate(User,Password))
  } else {
    req <- GET(paste('https://api.github.com/repos',GitHubRepo,'contents',studyDir,sep='/'))
  }
  contents <- content(req,as='parsed')
  files <- NULL
  for (i in seq(length(contents))) {
    files[i] <- paste(baseDirGitHub,contents[[i]]$path,sep='/')
  }
  xptFiles <- files[grep('.xpt',files)]
  if (!is.null(domainsOfInterest)) {
    domainsOfInterest <- paste(paste(dirname(xptFiles[1]),'/',domainsOfInterest,'.xpt',sep=''))
    xptFiles <- xptFiles[which(tolower(xptFiles) %in% tolower(domainsOfInterest))]
  }
  dataFrames <- list()
  count <- 0
  for (xptFile in xptFiles) {
    if (showProgress==T) {
      setProgress(value=count/length(xptFiles),message=paste0('Loading ',basename(xptFile),'...'))
    }
    count <- count + 1
    xptData <- sasxport.get(xptFile)
    colnames(xptData) <- toupper(colnames(xptData))
    dataFrames[[count]] <- xptData
  }
  names(dataFrames) <- tolower(file_path_sans_ext(basename(xptFiles)))
  return(dataFrames)
}

# Function to create a list of R dataframes for each .xpt file
# NOTE: this function requries the packages: "Hmisc" and "tools"
load.xpt.files <- function(path=getwd(),domainsOfInterest=NULL,showProgress=F) {
  xptFiles <- Sys.glob(paste(path,"*.xpt",sep='/'))
  if (!is.null(domainsOfInterest)) {
    domainsOfInterest <- paste(paste(path,'/',domainsOfInterest,'.xpt',sep=''))
    xptFiles <- xptFiles[which(tolower(xptFiles) %in% tolower(domainsOfInterest))]
  }
  dataFrames <- list()
  count <- 0
  for (xptFile in xptFiles) {
    if (showProgress==T) {
      setProgress(value=count/length(xptFiles),message=paste0('Loading ',basename(xptFile),'...'))
    }
    count <- count + 1
    xptData <- sasxport.get(xptFile)
    colnames(xptData) <- toupper(colnames(xptData))
    dataFrames[[count]] <- xptData
  }
  names(dataFrames) <- tolower(file_path_sans_ext(basename(xptFiles)))
  return(dataFrames)
}

# Function to create a list of R dataframes for each .csv file
load.csv.files <- function(path=getwd(),domainsOfInterest=NULL) {
  # NOTE: this function requries the packages: "tools"
  csvFiles <- Sys.glob(paste(path,"*.csv",sep='/'))
  if (!is.null(domainsOfInterest)) {
    domainsOfInterest <- paste(path,'/',domainsOfInterest,'.csv',sep='')
    csvFiles <- csvFiles[which(tolower(csvFiles) %in% tolower(domainsOfInterest))]
  }
  dataFrames <- list()
  count <- 0
  for (csvFile in csvFiles) {
    if (showProgress==T) {
      setProgress(value=count/length(xptFiles),message=paste0('Loading ',basename(xptFile),'...'))
    }
    count <- count + 1
    dataFrames[[count]] <- read.csv(csvFile)
  }
  names(dataFrames) <- tolower(file_path_sans_ext(basename(csvFiles)))
  return(dataFrames)
}


# Function to extract relevant fields and rename them
subTable <- function(fields,names,rawData) {
  count <- 0
  colIndex <- NA
  for (field in fields) {
    count <- count + 1
    if (length(which(colnames(rawData)==field))==1) { # test to make sure we get each column correctly
      index <- which(colnames(rawData)==field)
    } else {
      stop(paste(field,' Not Present in Dataset!',sep='')) # break and throw error message
    }
    colIndex[count] <- index
  }
  Data <- rawData[,colIndex]
  colnames(Data) <- names
  return(Data)
}

# Function to read a file from github
# NOTE: this function requries the package: "Hmisc"
read.github.xpt.file <- function (
    fName
  , bURL="https://raw.githubusercontent.com/phuse-org/phuse-scripts/master"
  , fPath="data/send/PDS/Xpt"
  , tDir=getwd() 
  ) {
  # bURL  = https://raw.githubusercontent.com/phuse-org/phuse-scripts/master
  # fPath = data/send/PDS/Xpt
  # fName = a_file_name
  # tDir  = target/local dir
  tFN <- paste(tDir,fName,sep='/')
  download.file(paste(bURL,fPath,fName,sep='/'),tFN,mode='wb')
  r <- sasxport.get(tFN)
  return(r)
}

# Function to get the value from field based on category in another field (e.g., check a TXVAL given a TXPARMCD and SETCD)
getFieldValue <- function(dataset,queryField,indexFields,indexValues) {
  for (i in 1:length(indexFields)) {
    indexTmp <- which(dataset[,indexFields[i]]==indexValues[i])
    if (i == 1) {
      index <- indexTmp
    } else {
      index <- intersect(index,indexTmp)
    }
  }
  fieldValue <- dataset[index,queryField]
  if (length(levels(dataset[,queryField])) > 0) {
    return(levels(dataset[,queryField])[fieldValue])
  } else {
    return(fieldValue)
  }
}


# Function to convert a simple ISO 8601 time duration as described in the SEND IG to seconds
# Returns NA if the fuction cannot convert the string to seconds
# This assumes that a month has 365.2425/12 days and that a year has 365.2425 days (see http://www.convertunits.com/from/second/to/year).
# Other ISO 8601 date times may be handled using https://cran.r-project.org/web/packages/parsedate/parsedate.pdf
# 
# DUR_to_seconds("P4S")  returns NA because the T is missing after the P
# DUR_to_seconds("-PT4S")  returns -4
# DUR_to_seconds("PT4S")   returns 4
# DUR_to_seconds("P1Y")    returns 31557600
#
#This function requires the library(stringr)
library(stringr)
DUR_to_seconds <- function(input) {
  s<-"^(\\+|-)?P((((([0-9]+(\\.[0-9]+)?)Y)?(([0-9]+(\\.[0-9]+)?)M)?(([0-9]+(\\.[0-9]+)?)D)?)(T(([0-9]+(\\.[0-9]+)?)H)?(([0-9]+(\\.[0-9]+)?)M)?(([0-9]+(\\.[0-9]+)?)S)?)?)|([0-9]+(\\.[0-9]+)?)W)$"
  result  <- str_match(input,s)
  if(str_detect(input,s))
  {
    # we have a time interval this script can handle
    result[is.na(result)] <- 0  # replace NA values with 0
    if(str_detect(input,"^-P"))
    {
      sign <- (-1)
    } else
    {
      sign <- (1)
    }
    year<-as.numeric(result[7])
    month<-as.numeric(result[10])
    day<-as.numeric(result[13])
    hour<-as.numeric(result[17])
    minute<-as.numeric(result[20])
    second<-as.numeric(result[23])
    week<-as.numeric(result[25])
    time<-sign*((((year*365.2425+month*(365.2425/12)+7*week+day)*24+hour)*60+minute)*60+second)
    return(time)
  } else 
  {
    return(NA)
  }
}


# Create a table with mean and se for a selected numeric field, based on user-defined grouping fields
# and carry over additional "other fields" that have only one value within groups (e.g., STUDYID)
createMeansTable <- function(dataset,meanField,groupFields,otherFields=NULL) {
  groups <- list()
  for (group in groupFields) {
    groups[[group]] <- unique(dataset[,group])
  }
  groupsDF <- expand.grid(groups)
  
  meanData <- NA
  sdData <- NA
  seData <- NA
  nData <- NA
  otherFieldList <- list()
  for (field in otherFields) {
    otherFieldList[[field]] <- rep(NA,nrow(groupsDF))
  }
  for (i in seq(nrow(groupsDF))) {
    index <- seq(nrow(dataset))
    for (j in seq(ncol(groupsDF))) {
      indexTmp <- which(dataset[,colnames(groupsDF)[j]]==groupsDF[i,j])
      index <- intersect(index,indexTmp)
    }
    meanData[i] <- mean(dataset[index,meanField],na.rm=TRUE)
    sdData[i] <- sd(dataset[index,meanField],na.rm=TRUE)
    seData[i] <- sd(dataset[index,meanField],na.rm=TRUE)/sqrt(length(which(is.finite(dataset[index,meanField]))))
    nData[i] <- length(which(is.na(dataset[index,meanField])==0))
    for (field in otherFields) {
      if (length(unique(dataset[index,field]))>1) {
        stop('otherField has too many values')
      } else if (length(unique(dataset[index,field]))==1) {
        if (length(levels(dataset[index,field]))>0) {
          otherFieldList[[field]][i] <- levels(dataset[,field])[dataset[index[1],field]]
        } else {
          otherFieldList[[field]][i] <- unique(dataset[index,field])
        }
      }
    }
  }
  newDataset <- cbind(groupsDF,meanData,sdData,seData,nData)
  for (field in otherFields) {
    newField <- otherFieldList[[field]]
    if (length(levels(newField))>0) {
      newDataset <- cbind(newDataset,levels(newField)[newField])
    } else {
      newDataset <- cbind(newDataset,newField)
    }
  }
  colnames(newDataset) <- c(groupFields,paste(meanField,'mean',sep='_'),paste(meanField,'sd',sep='_'),
                            paste(meanField,'se',sep='_'),paste(meanField,'n',sep='_'),otherFields)
  return(newDataset)
}
