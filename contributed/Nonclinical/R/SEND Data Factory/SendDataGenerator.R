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


# Get specimins for some domains
getSpecs <- function(aDomain) {
  switch(aDomain,
         "MI" = {aConfig <- getConfig("MI")},
         "MA" = {aConfig <- getConfig("MA")},
         "OM" = {aConfig <- getConfig("OM")},
  )
  aList <- list()  
  if (exists("aConfig")) {
    print("Obtaining specimen list")
    # later on, read from configuration file
    # for now, return 20 random tissueS
    nameList <- getCodeList(paste(aDomain,"SPEC",sep=""))
    for (i in 1:20) {
      aValue <- CTRandomName(nameList)
      aList <- append(aList,aValue)    
    }
  } else {
    print("No specimen list")
    aList <- append(aList,"No Specimen")  
  }
unique(aList)
}

# from configuration, get column based upon incoming column (like testcd to test)
getMatchColumn <- function(aDomain,aColumn1,aValue1,aColumn2) {
  configFiles <- list.files("configs)")
  #print(paste("Matching columns from ",aColumn1,aValue1,aColumn2))
  df1 <- unique(getConfig(aDomain)[aColumn1])
  df2 <- unique(getConfig(aDomain)[aColumn2])
  # FIXME might need other discriminating factors like Sex, Species,...
  # find position in first list
  df3 <- cbind(as.data.frame(df1), as.data.frame(df2)) 
  # get first matching one
  print(paste("        answer",df3[df3[1]==aValue1,][2][1]))
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
  print(paste0("Creating the data frames with columns: ",theColumns))
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
  
  #print(paste("Looping by SEX:",sexList))
  for (aSex in sexList) {
    # now loop on all groups
    print(paste("Looping by treatment:",treatmentList))
    for (aTreatment in treatmentList) {
      # now loop on all animals for which we want to create rows
      print(paste("Looping by animals per group:",animalsList))
      for (anAnimal in 1:animalsList) {
        # if this domain has days, loop over days
        if (hasDays(aDF,aDomain)) {
          # FIXME - use study length from configuration or user selection
          startDay <- 1
          endDay <- 10
        } else {
          startDay <- 1
          endDay <- 1  
        }
        # for Lab, just 1 day of data, last day of study
        if (aDomain=="LB") {
          startDay <- 10
          endDay <- 10
        }
        # for PC and PP, just 1 day of data, day 1
        if (aDomain=="PP" || aDomain=="PC") {
          startDay <- 1
          endDay <- 1
        }
        
        # for OM, MA and MI, just 1 day of data, last day of study
        if (aDomain=="MA" || aDomain=="MI" || aDomain=="OM") {
          startDay <- 10
          endDay <- 10
        }
        # deterimine specimens to use
        aSpecs <- getSpecs(aDomain)
        for (iDay in startDay:endDay) {
          # loop over the tests for this domain
          aCodes <- getTestCDs(aDomain, input$species)
          print(aCodes)
          for(i in 1:nrow(aCodes)) {
            aTestCD <-  as.character(aCodes[i,])
            if (!skipRow(aTestCD,iDay,endDay)) {
              for(iSpec in 1:length(aSpecs)) {
                aSpec <- as.character(aSpecs[iSpec])
                # print(paste(" About to create row animal for",aTestCD, iDay, anAnimal, aTreatment, aSex,aSpec))
                aRowList <<- createRowAnimal(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,
                input$studyName,aTestCD,iDay,aSpec)
                # replace empties with NA
                # print(paste(" inserting",aRowList))
                aRowList <<- sub("$^", NA, aRowList)
                aDF[aRow,] <<- aRowList        
                aRow <- aRow + 1
              } # end of loop on specimen
            } # end of skipRow check
          } # end of test loop
        } # end of day loop
      } # end of animal loop
    } # end of treament loop
  } # end of sex loop
  aDF
}

createRowAnimal <- function(aSex,aTreatment,anAnimal,aDF,aRow,aDomain,aStudyID,
                            aTestCD,iDay,aSpec) {
 aList <- list() 
 #print(paste("Creating row for:",aSex,aTreatment,anAnimal,aRow,aDomain,aStudyID,aTestCD))
 # print(paste("Getting values for:",labels(aDF)[2][[1]]))
 # loop on fields in data frame
 for (aCol in labels(aDF)[2][[1]]) {
   # add value to the list of column values, based upon the column name
   columnData <- getColumnData(aCol,aSex,aTreatment,anAnimal,aRow,aDomain,
                                aStudyID,aTestCD,iDay,aSpec)
   aList <- c(aList, columnData)
 }
 # print(paste("  FIXME values are:",aList))
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
      setProgress(value=percentOfList,message=paste('Producing dataset: ',aDomain))
      aDFName <- paste(tolower(aDomain),"Out",sep="")
      aDescription <- paste(aDomain,"domain") #FIXME - read description from SENDIG
      aDFReturned <<- createAnimalDataDomain(input,aDomain,aDescription,aDFName)
      aDFReturned <<- aDFReturned[, checkCore(aDFReturned)]
      # now reset the name of this dataframe to keep it
      assign(aDFName, aDFReturned, envir=.GlobalEnv)
      addToSet(aDomain,aDescription,aDFName)
    }
}
