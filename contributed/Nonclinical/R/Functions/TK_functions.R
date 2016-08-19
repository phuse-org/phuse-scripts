# Function to download all files from a GitHub folder
downloadGitHubFolder <- function(GitHubRepo,baseDirGitHub,studyDir) {
  # NOTE: this function requires the package: "httr"
  req <- GET(paste('https://api.github.com/repos',GitHubRepo,'contents',studyDir,sep='/'))
  contents <- content(req,as='parsed')
  for (i in seq(length(contents))) {
    filePath <- contents[[i]]$path
    download.file(paste(baseDirGitHub,filePath,sep='/'),basename(filePath),mode='wb')
  }
}

# Create function to check define.xml against .xpt files present


# Function to create R dataframes for each .xpt file
loadXPTfiles <- function(path=getwd()) {
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

# Create function write .xpt files from R data frames?

# Function to Extract Relevant Fields and Rename Them
createData <- function(fields,names,rawData) {
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