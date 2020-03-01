# These functions work together with the SendDataFactory

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
  aTestCD
}
getSENDLastTestCodeName <- function(aCol,aDomain) {
  # Retrieve from terminology, the test name matching the last test code
  nameList <- getCodeList(aCol)
  if (!is.null(nameList)&& nchar(nameList)>0) {
    aValue <- CTSearchOnCode(nameList,lastTestCode)
    # print(paste("Last test code is ",lastTestCode,aValue))
  } else {
    # some domains, this must come from a configuration file
    aValue <- getMatchColumn(aDomain,"testcd",lastTestCode,"test")
  }
  aValue
}
getOrres <- function(aDomain,aSex,aTestCD){
  
  aDomainConfig <- getConfig(aDomain)
  ## If Domain is numeric
  if(aDomain %in% c("BG", "BW", "EG", "FW", "LB", "PC", "PP", "VS")){
    ## If config found
    if(!is.null(aDomainConfig)) {
      print('here')
      testcd_ind <- str_which(names(aDomainConfig), "TESTCD")
      mean_ind <- str_which(names(aDomainConfig), "STRESM")
      sd_ind <- str_which(names(aDomainConfig), "STRESSD")
      aValueMean <- aDomainConfig[aDomainConfig$SEX == aSex &
                                    aDomainConfig[,testcd_ind] == aTestCD,
                                  sd_ind]
      aValue <- round(rnorm(1, aValueMean, aValueSD), digits=2)
      ## If config not found
    } else {
      aValue <- round(runif(1, 2.0, 100), digits=2)
    }
    ## If domain is catagorical
  } else {
    ## If config is found:
    if(!is.null(aDomainConfig)) {
      testcd_ind <- str_which(names(aDomainConfig), "TESTCD")
      fact_ind <- str_which(names(aDomainConfig), "FACT")
      prop_ind <- str_which(names(aDomainConfig), "PROP")
      
      ## Pull proportions for this sex,testcd
      testConfig <- aDomainConfig[aSex==aDomainConfig$SEX &
                                    aTestCD==aDomainConfig[,testcd_ind],]
      
      totalProportion <- sum(testConfig[,prop_ind])
      
      ## If Proportions don't sum to 1 the sample() fucntion will normalize
      if(totalProportion != 1) {
        warning(paste0(
          "Total Proportion for: ",
          aTestCD,
          " does not sum to 1: ",
          totalProportion,
          ", Normalizing to 1"
        ))
      }
      
      sample(testConfig[,fact_ind], size = 1, prob = testConfig[,prop_ind])
      
      
      ## If config is not found
    } else {
      nameList <- getCodeList(paste(aDomain,"STRESC",sep=""))
      aValue <- CTRandomName(nameList)
    }
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
  } else if (aCol=="PCORRESU") {
    aValue <- "ng/mL"
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
  # Next line for help in debugging
  # print(paste(" Getting column data for:",aCol,aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD),set=":")
  if (aCol=="DOMAIN") aData <- aDomain
  if (aCol=="STUDYID") {aData <- aStudyID}
  if (aCol==aSeqCol) {aData <- aRow}
  if (aCol=="USUBJID") {aData <- paste(aStudyID,"-",anAnimal,sep="")
  }
  if (aCol==aTestCDCol) {
    aData <- getSENDTestCode(aCol,aTestCD)
  }
  if (aCol==aTestCol)  {aData <- getSENDLastTestCodeName(aCol,aDomain)}
  if (aCol==aORRESCol) aData <- getOrres(aDomain,aSex,aTestCD)
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
