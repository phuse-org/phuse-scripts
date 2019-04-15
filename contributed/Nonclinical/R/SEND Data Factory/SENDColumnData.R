# These functions work together with the SendDataFactory

# get the list for use for a column from the SENDIG
getCodeList <- function(aCol){
  dfSENDIG[dfSENDIG$Column==aCol,]$Codelist[1]
}

# get a test code selection
getSENDTestCode <- function(aCol,aTestCD) {
  # use test code passed in  
  nameList <- getCodeList(aCol)
  if (!is.null(nameList)) {
    lastTestCode <<- CTSearchOnShortName(nameList,aTestCD)
  } else {
    # FIXME for some domains, this must come from a configuration file
    aValue <- "not set"
    lastTestCode <<- "not set"
  }
  # pass back same set code
  aTestCD
}
getSENDLastTestCodeName <- function(aCol) {
  # Retrieve from terminology, the test name matching the last test code
  nameList <- getCodeList(aCol)
  if (!is.null(nameList)) {
    aValue <- CTSearchOnCode(nameList,lastTestCode)
    # print(paste("Last test code is ",lastTestCode,aValue))
  } else {
    # FIXME for some domains, this must come from a configuration file
    aValue <- "not set"
  }
  aValue
}
getOrres <- function(aDomain){   
  # get from stresc value the codelist to use
  nameList <- getCodeList(paste(aDomain,"STRESC",sep=""))
  if (!is.na(nameList) && !is.null(nameList) && nchar(nameList)>0) {
    # print(paste("Orres randomize from: ",nameList,nchar(nameList)))
    aValue <- CTRandomName(nameList)
  } else {
    # FIXME - need from configuration if no codelist from corresponding stresc
    aValue <- round(runif(1, 2.0, 100),digits=2)
  }
  
  lastOrres <<- aValue 
  aValue
}

getSpec <- function(aDomain){   
  # get from the codelist to use
  nameList <- getCodeList(paste(aDomain,"SPEC",sep=""))
  if (!is.na(nameList) && !is.null(nameList) && nchar(nameList)>0) {
    aValue <- CTRandomName(nameList)
  } else {
    aValue <- "Not found"
  }
  
  lastOrres <<- aValue 
  aValue
}


getOrresUnit <- function(aCol){
  # should be tied by configuration to the ORRES value
  # get from stresc value the codelist to use
  nameList <- getCodeList(aCol)
  if (aCol=="BWORRESU" || aCol == "OMORRESU") {
    aValue <- "g"
  } else if (!is.null(nameList)) {
    aValue <- CTRandomName(nameList)
  } else {
    # FIXME - need from configuration if no codelist from corresponding stresc
    aValue <- "Not yet set"
  }
  lastOrresu <<- aValue 
  aValue
}
getStresc <- function(aCol){
  # for now assume it is the same as the last orres
  lastOrres
}
getStresuUnit <- function() {
  # for now assume it is the same as the orresu
  lastOrresu  
}

# returns column data based upon the column name
getColumnData <- function (aCol,aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD,iDay) {
  aData <- ""
  aSeqCol <- paste(aDomain,"SEQ",sep="")
  aTestCDCol <- paste(aDomain,"TESTCD",sep="")
  aTestCol <-paste(aDomain,"TEST",sep="")
  aORRESCol <- paste(aDomain,"ORRES",sep="")
  aSTRESCCol <-paste(aDomain,"STRESC",sep="")
  aSTRESNCol <- paste(aDomain,"STRESN",sep="")
  aORRESUCol <- paste(aDomain,"ORRESU",sep="")
  aSTRESUCol <- paste(aDomain,"STRESU",sep="")
  aSPECCol <- paste(aDomain,"SPEC",sep="")
  aDay <- paste(aDomain,"DY",sep="")
  aData <- NA
  # print(paste(" Getting column data for:",aCol,aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD),set=":")
  if (aCol=="DOMAIN") aData <- aDomain
  if (aCol=="STUDYID") {aData <- aStudyID}
  if (aCol==aSeqCol) {aData <- aRow}
  if (aCol=="USUBJID") {aData <- paste(aStudyID,"-",anAnimal,sep="")
  }
  if (aCol==aTestCDCol) {aData <- getSENDTestCode(aCol,aTestCD)}
  if (aCol==aTestCol)  {aData <- getSENDLastTestCodeName(aCol)}
  if (aCol==aORRESCol) aData <- getOrres(aDomain)
  if (aCol==aORRESUCol) {aData <- getOrresUnit(aCol)}
  if (aCol==aSTRESCCol) {aData <- getStresc(aCol)}
  if (aCol==aSTRESNCol) {aData <- suppressWarnings(as.numeric(lastOrres))}
  if (aCol==aSTRESUCol) {aData <- getStresuUnit()}
  if (aCol==aDay) {aData <- iDay}
  if (aCol=="VISITDY") {aData <- iDay}
  if (aCol==aSPECCol) aData <- getSpec(aDomain)
  # return the data
  aData
}
