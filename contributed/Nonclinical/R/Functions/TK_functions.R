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
# EXAMPLE: select all data collected before a particular date
# How to account for cage level linking with subjects?
# Identify nesting structures (nestings may overlap)


# > write.xpt (write .xpt file from R data frame)


# > SEND.to.xls (write an excel file with all .xpt files as different tabs or single files with a description tab)


####################################################################################



####################################################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!! Working Functions !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
####################################################################################


# Function to download all files from a GitHub folder
download.GitHub.folder <- function(GitHubRepo,baseDirGitHub,studyDir) {
  # NOTE: this function requires the package: "httr"
  req <- GET(paste('https://api.github.com/repos',GitHubRepo,'contents',studyDir,sep='/'))
  contents <- content(req,as='parsed')
  for (i in seq(length(contents))) {
    filePath <- contents[[i]]$path
    download.file(paste(baseDirGitHub,filePath,sep='/'),basename(filePath),mode='wb')
  }
}


# Function to create a list of R dataframes for each .xpt file
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
# NOTE: this function requries the packages: SASxport and Hmisc
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
  r <- read.xport(tFN)
  return(r)
}
