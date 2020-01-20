# These functions work together with the SendDataFactory


# 
skipRow <- function(aTestCD,iDay,endDay) {
  aResult <- FALSE
  # skip terminal body weight except on last day
  if (aTestCD=="TERMBW" && (iDay != endDay)) {
    aResult <- TRUE
  }
  aResult
}
#
## readConfig
# Input - List of configuration data.frames
# Output- List of configurations, which are lists of tests
readConfig <- function(configFile){
  
  if (class(configFile) != "data.frame") {
    stop(paste0("configFile must be a data.frame, it was ", class(configFile)))
  }
  
  #Detect columns for an observation configuration.
  configFileColumns <- names(configFile)
  catInd <- str_detect(configFileColumns, "(CAT)$")
  testInd <- str_detect(configFileColumns, "(TEST)$")
  testcdInd <- str_detect(configFileColumns, "(TESTCD)$")
  specInd <- str_detect(configFileColumns, "(SPEC)$")
  speciesInd <- str_detect(configFileColumns, "SPECIES")
  sexInd <- str_detect(configFileColumns, "SEX")
  meanInd <- str_detect(configFileColumns, "(STRESM)$")
  sdInd <- str_detect(configFileColumns, "(STRESSD)$")
  unitInd <- str_detect(configFileColumns, "(STRESU)$")
  factorInd <- str_detect(configFileColumns, "(FACT)$")
  proportionInd <- str_detect(configFileColumns,"(PROP)$")
  
  
  data.frame(
    cat = configFile[catInd],
    test = configFile[testInd],
    testcd = configFile[testcdInd],
    spec = configFile[specInd],
    species = configFile[speciesInd],
    sex = configFile[sexInd],
    mean = configFile[meanInd],
    sd = configFile[sdInd],
    unit = configFile[unitInd],
    fact = configFile[factorInd],
    prop = configFile[proportionInd]
  )
}

getConfig <- function(domain) {
  
  if(exists(paste0(domain, "config"))) {
    return(get0(paste0(domain, "config")))
  } else {
    if(file.exists(paste0("contributed/Nonclinical/R/SEND Data Factory/configs/", domain, "config.csv"))){
      print(paste0("Reading Configuration Files: ", domain))
      assign(paste0(domain,"config"), 
             readConfig(read.csv(paste0("contributed/Nonclinical/R/SEND Data Factory/configs/", 
                                        domain, "config.csv"), stringsAsFactors = FALSE)),
             envir = .GlobalEnv)
    } else {
      warning(paste0("Config Not Found in ", paste0("contributed/Nonclinical/R/SEND Data Factory/configs/", 
                                                    domain, "config.csv")))
      NULL
    }

  }
}

getTestCDs <- function(aDomain) {
  switch(aDomain,
         "BW" = {aConfig <- getConfig("BW")},
         "CL" = {aConfig <- getConfig("CL")},
         "LB" = {aConfig <- getConfig("LB")},
         "MI" = {aConfig <- getConfig("MI")},
         "PM" = {aConfig <- getConfig("PM")},
         "MA" = {aConfig <- getConfig("MA")},
         "OM" = {aConfig <- getConfig("OM")},
         "PP" = {aConfig <- getConfig("PP")},
         "PC" = {aConfig <- getConfig("PC")}
  )
  testcd_ind <- str_which(names(aConfig), "TESTCD")
  aList <- aConfig[,testcd_ind]
  print(aList)
  as.data.frame(unique(aList))
}

# from configuration, get column based upon incoming column (like testcd to test)
getMatchColumn <- function(aDomain,aColumn1,aValue1,aColumn2) {
  configFiles <- list.files("configs)")
  df1 <- unique(getConfig(aDomain)[aColumn1])
  df2 <- unique(getConfig(aDomain)[aColumn2])
  # FIXME might need other discriminating factors like Sex, Species,...
  # find position in first list
  df3 <- cbind(as.data.frame(df1), as.data.frame(df2)) 
  # get first matching one
  answer <- df3[df3[1]==aValue1,][2][1]
}

#check if data frame has a DY component
hasDays <- function(aDF,aDomain) {
  aDY <- paste(aDomain,"DY",sep="")
  aResult <- (aDY %in% labels(aDF)[2][[1]] )
  aResult
}

createAnimalDataDomain <- function(input,aDomain,aDescription,aDFName) {
  theColumns <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Column
  theLabels <- dfSENDIG[dfSENDIG$Domain==aDomain,]$Label
  # Creating the data fames
  print(paste("Creating the data frames with columns: ",theColumns))
  aDF <<- setNames(data.frame(matrix(ncol = length(theColumns), nrow = 1)),
                     theColumns
  )
  # set other global variables for use
  theTestArticle <<- input$testArticle
  # set labels for each field 
  index <- 1
  for (aColumn in theColumns) {
    Hmisc::label(aDF[[index]]) <<- theLabels[index]
    index <- index + 1
  }
  aRow <- 1
  # set some defaults
  if (is.null(input$sex)) {
    sexList <- c("M","F")
  } else {
    sexList <- input$sex
  }
    
  if (is.null(input$treatment)) {
    treatmentList <- c("Control Group")
  }  else {
    treatmentList <- input$treatment
  }
  if (is.null(input$animalsPerGroup)) {
    animalsList <- 10
  }  else {
    animalsList <- input$animalsPerGroup
  }
  
  # print(paste("Looping by SEX:",sexList))
  for (aSex in sexList) {
    # now loop on all groups
    # print(paste("Looping by treatment:",treatmentList))
    for (aTreatment in treatmentList) {
      # now loop on all animals for which we want to create rows
      # print(paste("Looping by animals per group:",animalsList))
      for (anAnimal in 1:animalsList) {
        # if this domain has days, loop over days
        if (hasDays(aDF,aDomain)) {
          # FIXME - use study length from configuration or user selection
          endDay <- 10
        } else {
          endDay <- 1  
        }
        for (iDay in 1:endDay) {
          # loop over the tests for this domain
          aCodes <- getTestCDs(aDomain)
          print(aCodes)
          for(i in 1:nrow(aCodes)) {
            aTestCD <- aCodes[i,]
            if (!skipRow(aTestCD,iDay,endDay)) {
            print(paste(" About to create row animal for",aTestCD, iDay, anAnimal, aTreatment, aSex))
            aRowList <<- createRowAnimal(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,
            input$studyName,aTestCD,iDay)
            # replace empties with NA
            # print(paste(" inserting",aRowList))
            aRowList <<- sub("$^", NA, aRowList)
            aDF[aRow,] <<- aRowList        
            aRow <- aRow + 1
            } # end of skipRow check
          } # end of test loop
        } # end of day loop
      } # end of animal loop
    } # end of treament loop
  } # end of sex loop
  aDF
}

createRowAnimal <- function(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,aStudyID,
                            aTestCD,iDay) {
 aList <- list() 
 # print(paste("Creating row for:",aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD))
 # print(paste("Getting values for:",labels(aDF)[2][[1]]))
 # loop on fields in data frame
 for (aCol in labels(aDF)[2][[1]]) {
   # add value to the list of column values, based upon the column name
   columnData <- getColumnData(aCol,aSex,aTreatment,anAnimal,aRow,aDomain,
                                aStudyID,aTestCD,iDay)
   aList <- c(aList, columnData)
 }
 # print(paste("  values are:",aList))
 # return the list of fields
 aList
}

setAnimalDataFiles <- function(input) {
    # Make a list of domains to handle
    DomainsList <- input$testCategories
    print(DomainsList)
    # create data frame based on structure
    # Loop on num domains
    index <- 0
    for (aDomain in DomainsList) {
      index <- index + 1
      percentOfList <- index/length(DomainsList)
      setProgress(value=percentOfList,message=paste('Producting dataset: ',aDomain))
      aDFName <- paste(tolower(aDomain),"Out",sep="")
      aDescription <- "FIXME - read description from SENDIG"
      aDFReturned <<- createAnimalDataDomain(input,aDomain,aDescription,aDFName)
      # now reset the name of this dataframe to keep it
      assign(aDFName, aDFReturned, envir=.GlobalEnv)
      addToSet(aDomain,aDescription,aDFName)
    }
}
